import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n.dart';
import '../l10n/mapped_strings.dart';
import '../map_style.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/live_session.dart';
import '../services/map_cache.dart';
import '../services/position_source.dart';
import '../theme/kumpas_theme.dart';
import '../widgets/lore_dialog.dart';

class LiveTrailScreen extends StatefulWidget {
  const LiveTrailScreen({
    super.key,
    required this.user,
    required this.detail,
  });

  final KumpasUser user;
  final QuestDetail detail;

  @override
  State<LiveTrailScreen> createState() => _LiveTrailScreenState();
}

class _LiveTrailScreenState extends State<LiveTrailScreen> {
  final ApiService _api = ApiService();
  final MapController _map = MapController();
  late final TileProvider? _tileProvider = MapCache.createTileProvider();

  late final PositionSource _source;
  SimulatedPositionSource? _simulated;
  StreamSubscription<GpsFix>? _subscription;
  Timer? _ticker;

  QuestDetail get detail => widget.detail;

  GpsFix? _fix;
  GpsFix? _lastCountingFix;
  Set<String> _unlocked = {};
  final Map<String, DateTime> _lastAttempt = {};

  List<TrailMessage> _messages = const [];

  DateTime _startedAt = DateTime.now();
  double _distanceMeters = 0;
  bool _follow = true;
  bool _mapReady = false;
  bool _finishing = false;
  String? _unlockingId;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _unlocked = {...detail.unlockedCheckpointIds};
    _source = widget.user.isTest
        ? (_simulated = SimulatedPositionSource(track: detail.track))
        : LivePositionSource();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = await LiveSessionStore.load();
    if (session != null && session.questId == detail.summary.id) {
      _startedAt = session.startedAt;
      _distanceMeters = session.distanceMeters;
    } else {
      _startedAt = DateTime.now();
      await LiveSessionStore.save(
        LiveSession(questId: detail.summary.id, startedAt: _startedAt),
      );
    }

    if (!mounted) return;
    setState(() {
      _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
    });

    _subscription = _source.stream.listen(
      _onFix,
      onError: (Object error) {
        if (!mounted) return;
        _showSnack(localizedError(context, error.toString()));
      },
    );

    if (_simulated != null) {
      final start = detail.track.isNotEmpty
          ? detail.track.first
          : detail.checkpoints.first.latLng;
      _simulated!.teleport(start);
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
      });
    });

    _loadMessages();
    _flushPendingUnlocks();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _subscription?.cancel();
    _source.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // GPS
  // -------------------------------------------------------------------------

  void _onFix(GpsFix fix) {
    final previous = _lastCountingFix;
    var added = 0.0;
    if (previous != null) {
      final distance = const Distance().as(LengthUnit.Meter, previous.latLng, fix.latLng);
      // Saltos grandes são teleportes/erros de GPS — não contam para a distância.
      if (distance > 1 && distance < 150) added = distance;
    }
    _lastCountingFix = fix;

    if (!mounted) return;
    setState(() {
      _fix = fix;
      _distanceMeters += added;
    });

    if (_follow && _mapReady) {
      _map.move(fix.latLng, _map.camera.zoom);
    }

    if (added > 0) {
      _saveSession();
    }

    _checkAutoUnlock(fix);
  }

  Future<void> _saveSession() async {
    await LiveSessionStore.save(
      LiveSession(
        questId: detail.summary.id,
        startedAt: _startedAt,
        distanceMeters: _distanceMeters,
      ),
    );
  }

  double _distanceTo(Checkpoint checkpoint) {
    final fix = _fix;
    if (fix == null) return double.infinity;
    return const Distance()
        .as(LengthUnit.Meter, fix.latLng, checkpoint.latLng);
  }

  Checkpoint? get _nextCheckpoint {
    final pending = detail.checkpoints
        .where((checkpoint) => !_unlocked.contains(checkpoint.id))
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return pending.first;
  }

  Future<void> _checkAutoUnlock(GpsFix fix) async {
    if (_unlockingId != null) return;

    for (final checkpoint in detail.checkpoints) {
      if (_unlocked.contains(checkpoint.id)) continue;
      final distance = const Distance()
          .as(LengthUnit.Meter, fix.latLng, checkpoint.latLng);
      if (distance > checkpoint.radiusMeters) continue;

      final last = _lastAttempt[checkpoint.id];
      if (last != null && DateTime.now().difference(last).inSeconds < 25) {
        continue;
      }

      _lastAttempt[checkpoint.id] = DateTime.now();
      await _unlock(checkpoint, fix);
      return;
    }
  }

  Future<void> _unlock(Checkpoint checkpoint, GpsFix fix) async {
    setState(() => _unlockingId = checkpoint.id);

    try {
      final result = await _api.unlockCheckpoint(
        userId: widget.user.id,
        checkpointId: checkpoint.id,
        userLat: fix.lat,
        userLng: fix.lng,
        lang: context.l10n.localeName,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _unlocked = {..._unlocked, checkpoint.id});
        await showLoreDialog(
          context,
          title: result.title ?? checkpoint.title,
          content: result.content ?? checkpoint.lore,
          xpGained: result.xpGained,
          questCompleted: result.questCompleted,
          imageUrl: checkpoint.imageUrl,
          loreSource: result.source ?? checkpoint.loreSource,
          imageCredit: checkpoint.imageCredit,
        );
      } else {
        _showSnack(result.message);
      }
    } catch (error) {
      // Sem rede: guarda para sincronizar mais tarde.
      await PendingUnlockStore.add(
        PendingUnlock(
          questId: detail.summary.id,
          checkpointId: checkpoint.id,
          lat: fix.lat,
          lng: fix.lng,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      _showSnack(context.l10n.liveOfflineSync);
    } finally {
      if (mounted) setState(() => _unlockingId = null);
    }
  }

  Future<void> _flushPendingUnlocks() async {
    final pending = await PendingUnlockStore.list();
    for (final item in pending) {
      try {
        final result = await _api.unlockCheckpoint(
          userId: widget.user.id,
          checkpointId: item.checkpointId,
          userLat: item.lat,
          userLng: item.lng,
        );
        if (result.success) {
          await PendingUnlockStore.remove(item.checkpointId);
          if (mounted && item.questId == detail.summary.id) {
            setState(() => _unlocked = {..._unlocked, item.checkpointId});
          }
        }
      } catch (_) {
        break; // continua offline
      }
    }
  }

  // -------------------------------------------------------------------------
  // Recados
  // -------------------------------------------------------------------------

  Future<void> _loadMessages() async {
    try {
      final messages = await _api.getMessages(detail.summary.id, widget.user.id);
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (_) {
      // offline: mantém os que já tem
    } finally {
    }
  }

  Future<void> _toggleLike(TrailMessage message) async {
    try {
      final result = await _api.toggleMessageLike(message.id, widget.user.id);
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (item) => item.id == message.id
                  ? item.copyWith(
                      likedByMe: result.liked,
                      likeCount: result.likeCount,
                    )
                  : item,
            )
            .toList();
      });
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    }
  }

  Future<void> _report(TrailMessage message) async {
    try {
      await _api.reportMessage(message.id, widget.user.id);
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((item) => item.id != message.id).toList();
      });
      _showSnack(context.l10n.messagesReported);
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    }
  }

  Future<void> _openMessagesSheet() async {
    await _loadMessages();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KumpasPalette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      context.l10n.messagesHeader,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: KumpasPalette.ink,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _composeMessage();
                      },
                      icon: const Icon(Icons.add_comment_outlined, size: 17),
                      label: Text(context.l10n.liveRecado),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.l10n.messagesEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: KumpasPalette.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _MessageTile(
                            message: message,
                            onLike: () async {
                              await _toggleLike(message);
                              setSheetState(() {});
                            },
                            onReport: () async {
                              await _report(message);
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _composeMessage() async {
    final fix = _fix;
    if (fix == null) {
      _showSnack(context.l10n.messagesPositionUnknown);
      return;
    }

    final result = await showModalBottomSheet<({String category, String text})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KumpasPalette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ComposeMessageSheet(),
    );

    if (result == null || !mounted) return;

    try {
      await _api.postMessage(
        questId: detail.summary.id,
        userId: widget.user.id,
        category: result.category,
        text: result.text,
        lat: fix.lat,
        lng: fix.lng,
      );
      await _loadMessages();
      if (!mounted) return;
      _showSnack(context.l10n.messagesPosted, error: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // GPS simulado
  // -------------------------------------------------------------------------

  Future<void> _openSimulatorPanel() async {
    final sim = _simulated;
    if (sim == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KumpasPalette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.simulatorTitle,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: KumpasPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.simulatorHint,
                style: const TextStyle(fontSize: 12, color: KumpasPalette.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: detail.checkpoints.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final checkpoint = detail.checkpoints[index];
                    return ActionChip(
                      label: Text('${checkpoint.order}. ${checkpoint.title}'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        sim.teleport(checkpoint.latLng);
                        _showSnack(context.l10n.simulatorTeleported(checkpoint.title), error: false);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        sim.startWalking();
                        _showSnack(context.l10n.simulatorStarting, error: false);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(context.l10n.simulatorStart),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      sim.stop();
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.pause),
                    label: Text(context.l10n.simulatorStop),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Fim da trilha
  // -------------------------------------------------------------------------

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.liveFinishTitle),
        content: Text(
          context.l10n.liveFinishBody(
            _formatDistance(_distanceMeters),
            _formatDuration(_elapsedSeconds),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.liveKeepGoing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.liveFinish),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _finishing = true);
    await LiveSessionStore.clear();
    _subscription?.cancel();
    _ticker?.cancel();
    await _source.dispose();
    if (mounted) Navigator.of(context).pop(true);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _showSnack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? KumpasPalette.danger : KumpasPalette.forestDark,
        ),
      );
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h${minutes.toString().padLeft(2, '0')}';
    return '${minutes}min';
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  int _nearestTrackIndex(GpsFix? fix) {
    if (fix == null || detail.track.isEmpty) return -1;
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < detail.track.length; i++) {
      final distance = const Distance()
          .as(LengthUnit.Meter, fix.latLng, detail.track[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  bool get _offRoute {
    final fix = _fix;
    if (fix == null || detail.track.isEmpty) return false;
    final index = _nearestTrackIndex(fix);
    return const Distance().as(
          LengthUnit.Meter,
          fix.latLng,
          detail.track[index],
        ) >
        80;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextCheckpoint;
    final nextDistance = next == null ? null : _distanceTo(next);
    final start = _fix?.latLng ??
        (detail.track.isNotEmpty ? detail.track.first : detail.summary.center.latLng);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveSession();
        if (!context.mounted) return;
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: start,
                initialZoom: 16,
                minZoom: 10,
                maxZoom: 18,
                backgroundColor: KumpasPalette.mapCanvas,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _mapReady = true;
                  final fix = _fix;
                  if (fix != null) _map.move(fix.latLng, 16);
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveStart) {
                    setState(() => _follow = false);
                  }
                },
                onLongPress: _simulated == null
                    ? null
                    : (tapPosition, point) {
                        _simulated!.teleport(point);
                        setState(() => _follow = true);
                        _showSnack(context.l10n.simulatorMoved, error: false);
                      },
              ),
              children: [
                TileLayer(
                  urlTemplate: kMapTileUrl,
                  userAgentPackageName: kMapUserAgent,
                  tileProvider: _tileProvider,
                  maxNativeZoom: MapCache.maxNativeZoom,
                  errorTileCallback: MapCache.noteTileError,
                ),
                if (detail.track.length > 1) ...[
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: detail.track,
                        strokeWidth: 5,
                        color: KumpasPalette.muted.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final index = _nearestTrackIndex(_fix);
                      if (index <= 0) return const SizedBox.shrink();
                      return PolylineLayer(
                        polylines: [
                          Polyline(
                            points: detail.track.sublist(0, index + 1),
                            strokeWidth: 6,
                            color: KumpasPalette.forest,
                          ),
                        ],
                      );
                    },
                  ),
                ],
                MarkerLayer(
                  markers: [
                    ...detail.checkpoints.map(
                      (checkpoint) => Marker(
                        point: checkpoint.latLng,
                        width: 40,
                        height: 40,
                        child: _checkpointMarker(checkpoint),
                      ),
                    ),
                    ..._messages.map(
                      (message) => Marker(
                        point: message.latLng,
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: _openMessagesSheet,
                          child: _messageMarker(message),
                        ),
                      ),
                    ),
                    if (_fix != null)
                      Marker(
                        point: _fix!.latLng,
                        width: 54,
                        height: 54,
                        child: _userMarker(),
                      ),
                  ],
                ),
                SimpleAttributionWidget(
                  source: Text(kMapAttribution),
                  alignment: Alignment.bottomRight,
                  backgroundColor: Colors.white70,
                ),
              ],
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  _buildBottomCard(next, nextDistance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.liveBack,
            onPressed: () {
              final navigator = Navigator.of(context);
              _saveSession().then((_) {
                if (mounted) navigator.pop(false);
              });
            },
            icon: const Icon(Icons.arrow_back),
            color: KumpasPalette.ink,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.summary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KumpasPalette.ink,
                  ),
                ),
                Text(
                  '${_formatDuration(_elapsedSeconds)} · ${_formatDistance(_distanceMeters)}'
                  '${_fix?.simulated == true ? ' · ${context.l10n.liveSimulatedGps}' : ''}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: KumpasPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.messagesHeader,
            onPressed: _openMessagesSheet,
            icon: Badge(
              isLabelVisible: _messages.isNotEmpty,
              label: Text('${_messages.length}'),
              backgroundColor: KumpasPalette.amber,
              child: const Icon(Icons.forum_outlined, color: KumpasPalette.forestDark),
            ),
          ),
          IconButton(
            tooltip: context.l10n.liveFollow,
            onPressed: () {
              setState(() => _follow = !_follow);
              final fix = _fix;
              if (_follow && fix != null) _map.move(fix.latLng, 16);
            },
            icon: Icon(
              _follow ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: KumpasPalette.forest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Checkpoint? next, double? nextDistance) {
    final total = detail.checkpoints.length;
    final progress = total == 0 ? 0.0 : _unlocked.length / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_offRoute)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: KumpasPalette.amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: KumpasPalette.amberDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.liveOffRoute,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KumpasPalette.amberDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: KumpasPalette.forestLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined, color: KumpasPalette.forest),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null ? context.l10n.liveTrailComplete : context.l10n.liveNextCheckpoint,
                      style: const TextStyle(
                        fontSize: 11,
                        color: KumpasPalette.muted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      next == null ? context.l10n.liveAllValidated : next.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KumpasPalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (nextDistance != null && nextDistance.isFinite)
                Text(
                  _formatDistance(nextDistance),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KumpasPalette.forestDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: KumpasPalette.paperDark,
              valueColor: const AlwaysStoppedAnimation(KumpasPalette.forest),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.liveCheckpointsValidated('${_unlocked.length}', '$total'),
            style: const TextStyle(fontSize: 11, color: KumpasPalette.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _composeMessage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.add_comment_outlined, size: 17),
                  label: Text(context.l10n.liveRecado, maxLines: 1),
                ),
              ),
              if (_simulated != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _openSimulatorPanel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(context.l10n.liveGpsButton, maxLines: 1),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _finishing ? null : _finish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(context.l10n.liveFinish, maxLines: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkpointMarker(Checkpoint checkpoint) {
    final unlocked = _unlocked.contains(checkpoint.id);
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? KumpasPalette.forest : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: KumpasPalette.forest, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: unlocked
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '${checkpoint.order}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KumpasPalette.forestDark,
                ),
              ),
      ),
    );
  }

  Widget _messageMarker(TrailMessage message) {
    final color = switch (message.category) {
      'perigo' => KumpasPalette.danger,
      'aviso' => KumpasPalette.amber,
      _ => KumpasPalette.forest,
    };
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.chat_bubble, color: Colors.white, size: 16),
    );
  }

  Widget _userMarker() {
    return Transform.rotate(
      angle: ((_fix?.heading ?? 0) * math.pi) / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            child: Icon(Icons.navigation, size: 24, color: Color(0xFF1A73E8)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes auxiliares
// ---------------------------------------------------------------------------

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.onLike,
    required this.onReport,
  });

  final TrailMessage message;
  final VoidCallback onLike;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (message.category) {
      'perigo' => (KumpasPalette.danger, Icons.dangerous_outlined, context.l10n.catDanger),
      'aviso' => (KumpasPalette.amber, Icons.warning_amber, context.l10n.catWarning),
      _ => (KumpasPalette.forest, Icons.tips_and_updates_outlined, context.l10n.catTip),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KumpasPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                _relativeTime(context, message.createdAt),
                style: const TextStyle(fontSize: 10.5, color: KumpasPalette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: const TextStyle(fontSize: 13.5, height: 1.35, color: KumpasPalette.ink),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                message.userName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KumpasPalette.muted,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  message.likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 15,
                ),
                label: Text('${message.likeCount}'),
              ),
              IconButton(
                tooltip: context.l10n.messagesReport,
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined, size: 16),
                color: KumpasPalette.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _relativeTime(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.timeNow;
    if (diff.inHours < 1) return l10n.timeMinutes('${diff.inMinutes}');
    if (diff.inDays < 1) return l10n.timeHours('${diff.inHours}');
    return l10n.timeDays('${diff.inDays}');
  }
}

class _ComposeMessageSheet extends StatefulWidget {
  const _ComposeMessageSheet();

  @override
  State<_ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet> {
  final TextEditingController _controller = TextEditingController();
  String _category = 'dica';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.messagesCompose,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KumpasPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.messagesComposeHint,
            style: const TextStyle(fontSize: 12, color: KumpasPalette.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in [
                ('dica', context.l10n.catTip, Icons.tips_and_updates_outlined),
                ('aviso', context.l10n.catWarning, Icons.warning_amber),
                ('perigo', context.l10n.catDanger, Icons.dangerous_outlined),
              ])
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$3, size: 15),
                      const SizedBox(width: 4),
                      Text(entry.$2),
                    ],
                  ),
                  selected: _category == entry.$1,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = entry.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 280,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.messagesComposePlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.length < 3) return;
                Navigator.of(context).pop((category: _category, text: text));
              },
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(context.l10n.messagesPublish),
            ),
          ),
        ],
      ),
    );
  }
}
