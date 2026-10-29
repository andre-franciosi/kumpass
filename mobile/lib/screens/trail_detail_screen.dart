import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n.dart';
import '../l10n/mapped_strings.dart';
import '../map_style.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/live_session.dart';
import '../services/location_service.dart';
import '../services/map_cache.dart';
import '../services/plan_repository.dart';
import '../theme/kumpas_theme.dart';
import '../widgets/compass_rose.dart';
import '../widgets/lore_dialog.dart';
import '../widgets/ui.dart';
import 'live_trail_screen.dart';

class TrailDetailScreen extends StatefulWidget {
  const TrailDetailScreen({
    super.key,
    required this.user,
    required this.questId,
    this.initial,
    this.localeCode = 'pt',
  });

  final KumpasUser user;
  final String questId;
  final QuestSummary? initial;
  final String localeCode;

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  final ApiService _api = ApiService();
  final LocationService _location = LocationService();
  final PlanRepository _plans = LocalPlanRepository.instance;

  QuestDetail? _detail;
  HikePlan? _plan;
  Set<String> _unlocked = {};
  bool _loading = true;
  bool _savingPlan = false;
  bool _completed = false;
  String? _error;
  String? _loadingCheckpointId;

  bool _offline = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  List<ScoredWeather> _bestDays = const [];
  ScoredWeather? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  LiveSession? _liveSession;
  List<TrailMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object?>([
        _api.getQuest(widget.questId, widget.user.id, lang: widget.localeCode),
        _plans.load(widget.questId),
      ]);

      final detail = results[0] as QuestDetail;
      final saved = results[1] as HikePlan?;
      final plan = saved ??
          HikePlan(
            questId: widget.questId,
            date: null,
            groupSize: 2,
            transport: 'car',
            checklist: {for (final item in kPlanChecklistItems) item: false},
          );

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _plan = plan;
        _unlocked = {...detail.unlockedCheckpointIds};
        _completed = detail.summary.isCompleted;
        _loading = false;
        _error = null;
      });

      _loadOfflineState();
      _loadBestDays();
      _loadSession();
      _loadMessagesPreview();

      if (plan.date != null) {
        _loadWeather(plan.date!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadDetail() async {
    try {
      final detail = await _api.getQuest(
        widget.questId,
        widget.user.id,
        lang: widget.localeCode,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _unlocked = {...detail.unlockedCheckpointIds};
        if (detail.summary.isCompleted) _completed = true;
      });
    } catch (_) {
      // Silencioso: mantém o estado atual.
    }
  }

  bool get _prepReady =>
      (_plan?.checklistCompleted ?? false) &&
      _weather != null &&
      _weather!.isGood;

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadOfflineState() async {
    final offline = await MapCache.isOffline(widget.questId);
    if (!mounted) return;
    setState(() => _offline = offline);
  }

  Future<void> _loadBestDays() async {
    try {
      final days = await _api.getBestDays(
        widget.questId,
        lang: context.l10n.localeName,
      );
      if (!mounted) return;
      setState(() => _bestDays = days);
    } catch (_) {
      // Sem previsão: o plano continua a funcionar.
    }
  }

  Future<void> _loadSession() async {
    final session = await LiveSessionStore.load();
    if (!mounted) return;
    setState(() {
      _liveSession =
          session != null && session.questId == widget.questId ? session : null;
    });
  }

  Future<void> _loadMessagesPreview() async {
    try {
      final messages = await _api.getMessages(widget.questId, widget.user.id);
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (_) {
      // offline: mantém
    }
  }

  Future<void> _openLiveTrail() async {
    final detail = _detail;
    if (detail == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveTrailScreen(user: widget.user, detail: detail),
      ),
    );

    if (!mounted) return;
    await _reloadDetail();
    await _loadSession();
    await _loadMessagesPreview();
  }

  Future<void> _loadWeather(DateTime date) async {
    final center = _detail?.summary.center;
    if (center == null) return;

    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final weather = await _api.getWeather(
        lat: center.lat,
        lng: center.lng,
        date: _isoDate(date),
        lang: context.l10n.localeName,
      );
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _weatherLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weather = null;
        _weatherError = e.toString();
        _weatherLoading = false;
      });
    }
  }

  Future<void> _validateCheckpoint(Checkpoint checkpoint) async {
    setState(() => _loadingCheckpointId = checkpoint.id);

    try {
      final position = await _location.getCurrentPosition();
      final result = await _api.unlockCheckpoint(
        userId: widget.user.id,
        checkpointId: checkpoint.id,
        userLat: position.latitude,
        userLng: position.longitude,
        lang: widget.localeCode,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _unlocked = {..._unlocked, checkpoint.id};
          if (result.questCompleted) _completed = true;
        });
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
        await _reloadDetail();
      } else {
        _showSnackBar(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingCheckpointId = null);
    }
  }

  void _showSnackBar(String message, {bool error = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : kPrimary,
        ),
      );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _plan?.date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: context.l10n.planDateHelp,
    );

    if (picked != null && mounted) {
      setState(() => _plan = _plan?.copyWith(date: picked));
      await _loadWeather(picked);
    }
  }

  Future<void> _downloadOffline() async {
    final detail = _detail;
    if (detail == null || _downloading) return;

    final bounds = detail.summary.bbox?.latLngBounds ??
        (detail.track.isNotEmpty
            ? LatLngBounds.fromPoints(detail.track)
            : LatLngBounds.fromPoints(
                detail.checkpoints.map((c) => c.latLng).toList(),
              ));

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    try {
      await MapCache.downloadRegion(
        questId: widget.questId,
        bounds: bounds,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() => _offline = true);
      _showSnackBar(context.l10n.offlineDownloaded, error: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context.l10n.offlineDownloadError(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = 0;
        });
      }
    }
  }

  Future<void> _clearOffline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.offlineDeleteTitle),
        content: Text(context.l10n.offlineDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await MapCache.clearAll();
      if (!mounted) return;
      setState(() => _offline = false);
      _showSnackBar(context.l10n.offlineDeleted, error: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context.l10n.offlineDeleteError(e.toString()));
    }
  }

  Future<void> _savePlan() async {
    final plan = _plan;
    if (plan == null) return;

    setState(() => _savingPlan = true);
    await _plans.save(plan);
    if (!mounted) return;
    setState(() => _savingPlan = false);

    _showSnackBar(
      _prepReady
          ? context.l10n.planSavedPrep(localizedWeatherRating(context, _weather?.rating ?? ''))
          : context.l10n.planSavedLocal,
      error: false,
    );
  }

  Future<void> _openReviewSheet() async {
    final result = await showModalBottomSheet<_ReviewResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewSheet(
        initialRating: _detail?.userReview?.rating ?? 0,
        initialComment: _detail?.userReview?.comment,
      ),
    );

    // Sheet dispensado sem publicar.
    if (result == null || !mounted) return;

    try {
      await _api.submitReview(
        questId: widget.questId,
        userId: widget.user.id,
        rating: result.rating,
        comment: result.comment,
      );
      await _reloadDetail();
      if (!mounted) return;
      _showSnackBar(context.l10n.reviewPublished, error: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || detail == null
              ? _DetailError(message: _error ?? 'Erro', onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _reloadDetail,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: 260,
                        stretch: true,
                        backgroundColor: KumpasPalette.forest,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(
                            left: 60,
                            right: 16,
                            bottom: 12,
                          ),
                          title: Text(
                            detail.summary.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          background: _Hero(detail: detail),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _StatsRow(detail: detail),
                            const SizedBox(height: 14),
                            _LiveTrailCard(
                              session: _liveSession,
                              completed: _completed,
                              onStart: _openLiveTrail,
                            ),
                            if (_completed) ...[
                              const SizedBox(height: 12),
                              const _CompletedBanner(),
                            ],
                            const SizedBox(height: 16),
                            _DifficultyCard(detail: detail),
                            const SizedBox(height: 16),
                            _TrailMiniMap(
                              detail: detail,
                              unlocked: _unlocked,
                              offline: _offline,
                            ),
                            const SizedBox(height: 10),
                            _OfflineCard(
                              offline: _offline,
                              downloading: _downloading,
                              progress: _downloadProgress,
                              available: MapCache.isReady,
                              onDownload: _downloadOffline,
                              onClear: _clearOffline,
                            ),
                            const SizedBox(height: 16),
                            _PlanCard(
                              plan: _plan,
                              saving: _savingPlan,
                              weather: _weather,
                              weatherLoading: _weatherLoading,
                              weatherError: _weatherError,
                              bestDays: _bestDays,
                              prepReady: _prepReady,
                              onPickDate: _pickDate,
                              onSelectDay: (day) {
                                final date = day.dateTime;
                                if (date == null) return;
                                setState(() {
                                  _plan = _plan?.copyWith(date: date);
                                  _weather = day;
                                });
                              },
                              onGroupSize: (size) => setState(
                                () => _plan = _plan?.copyWith(groupSize: size),
                              ),
                              onTransport: (t) => setState(
                                () => _plan = _plan?.copyWith(transport: t),
                              ),
                              onToggleItem: (item, value) => setState(() {
                                final checklist = {...?_plan?.checklist, item: value};
                                _plan = _plan?.copyWith(checklist: checklist);
                              }),
                              onSave: _savePlan,
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              title: context.l10n.checkpointsTitle,
                              trailing:
                                  '${_unlocked.length}/${detail.checkpoints.length}',
                            ),
                            const SizedBox(height: 10),
                            _CheckpointTimeline(
                              checkpoints: detail.checkpoints,
                              unlocked: _unlocked,
                              loadingId: _loadingCheckpointId,
                              onValidate: _validateCheckpoint,
                            ),
                            const SizedBox(height: 12),
                            const _RewardTeaser(),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: context.l10n.messagesTitle,
                              trailing: '${_messages.length}',
                            ),
                            const SizedBox(height: 8),
                            _MessagesPreview(
                              messages: _messages,
                              onOpen: _openLiveTrail,
                            ),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: context.l10n.reviewsTitle,
                              trailing: '${detail.summary.ratingCount}',
                            ),
                            const SizedBox(height: 8),
                            _ReviewsSection(
                              detail: detail,
                              onReview: _openReviewSheet,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero / cabeçalho
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.detail});

  final QuestDetail detail;

  @override
  Widget build(BuildContext context) {
    final quest = detail.summary;

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (quest.imageUrl != null)
            Image.network(
              quest.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _HeroFallback(),
            )
          else
            const _HeroFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.black87],
              ),
            ),
          ),
          if (quest.imageCredit != null && quest.imageCredit!.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                context.l10n.photoCredit(quest.imageCredit ?? ''),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(
                      icon: Icons.place,
                      label: localizedRegion(context, quest.region),
                      background: Colors.white,
                      foreground: kPrimaryDark,
                    ),
                    const SizedBox(width: 8),
                    DifficultyBadge(level: quest.difficulty, label: quest.difficultyLabel),
                  ],
                ),
                const SizedBox(height: 6),
                StarRating(
                  rating: quest.ratingAvg,
                  showValue: true,
                  count: quest.ratingCount,
                  size: 17,
                  valueColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, Color(0xFF66BB6A)],
        ),
      ),
      child: Center(child: Icon(Icons.terrain, size: 80, color: Colors.white24)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estatísticas e dificuldade
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.detail});

  final QuestDetail detail;

  @override
  Widget build(BuildContext context) {
    final quest = detail.summary;

    return Row(
      children: [
        _Stat(icon: Icons.straighten, value: '${quest.distanceKm} km', label: context.l10n.statDistance),
        _Stat(icon: Icons.schedule, value: formatDuration(quest.durationMin), label: context.l10n.statDuration),
        _Stat(icon: Icons.trending_up, value: '${quest.elevationGainM} m', label: context.l10n.statElevation),
        _Stat(icon: Icons.bolt, value: '${quest.xpReward}', label: context.l10n.statXp),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KumpasPalette.line),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: KumpasPalette.amber),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: KumpasPalette.ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: KumpasPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.detail});

  final QuestDetail detail;

  @override
  Widget build(BuildContext context) {
    final b = detail.breakdown;
    final level = detail.summary.difficulty;
    final color = difficultyColor(level);
    final progress = (b.score / 110).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(difficultyIcon(level), color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizedDifficultyTitle(context, detail.summary.difficulty, detail.summary.difficultyLabel),
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: color,
                  ),
                ),
              ),
              Text(
                context.l10n.pointsLabel(b.score.toStringAsFixed(0)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.levelExplainer,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FormulaChip(label: '${b.distanceKm} km', factor: '×3'),
              _FormulaChip(label: '${b.durationMin} min', factor: '×0,12'),
              _FormulaChip(label: '${b.elevationGainM} m D+', factor: '×0,05'),
              _FormulaChip(label: '${b.checkpointCount} checkpoints', factor: '×4'),
              _FormulaChip(label: context.l10n.terrainLabel, factor: '×${b.terrainFactor}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaChip extends StatelessWidget {
  const _FormulaChip({required this.label, required this.factor});

  final String label;
  final String factor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KumpasPalette.line),
      ),
      child: Text(
        '$label $factor',
        style: const TextStyle(fontSize: 10.5, color: KumpasPalette.muted),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.completedRewardBanner,
              style: const TextStyle(
                color: kPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini-mapa
// ---------------------------------------------------------------------------

class _TrailMiniMap extends StatefulWidget {
  const _TrailMiniMap({
    required this.detail,
    required this.unlocked,
    required this.offline,
  });

  final QuestDetail detail;
  final Set<String> unlocked;
  final bool offline;

  @override
  State<_TrailMiniMap> createState() => _TrailMiniMapState();
}

class _TrailMiniMapState extends State<_TrailMiniMap> {
  final MapController _controller = MapController();
  late final TileProvider? _tileProvider = MapCache.createTileProvider();

  QuestDetail get detail => widget.detail;
  Set<String> get unlocked => widget.unlocked;
  bool get offline => widget.offline;

  @override
  Widget build(BuildContext context) {
    final points = detail.track.isNotEmpty
        ? detail.track
        : detail.checkpoints.map((c) => c.latLng).toList();
    final center = points.isEmpty
        ? detail.summary.center.latLng
        : LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: context.l10n.mapTrailTitle),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 230,
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                maxZoom: offline ? MapCache.maxNativeZoom.toDouble() : 18,
                backgroundColor: const Color(0xFFDCEDC8),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                // O fit é aplicado depois do layout — evita o bug em que o
                // flutter_map 8 mantinha a câmara no centro por defeito.
                onMapReady: () {
                  if (points.length > 1) {
                    _controller.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(46),
                      ),
                    );
                  }
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
                if (points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4,
                        color: kPrimary.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: detail.checkpoints
                      .map(
                        (cp) => Marker(
                          point: cp.latLng,
                          width: 34,
                          height: 34,
                          child: Container(
                            decoration: BoxDecoration(
                              color: unlocked.contains(cp.id)
                                  ? kPrimary
                                  : Colors.grey.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Center(
                              child: unlocked.contains(cp.id)
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Text(
                                      '${cp.order}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SimpleAttributionWidget(
                  source: Text(kMapAttribution),
                  alignment: Alignment.bottomRight,
                  backgroundColor: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mapas offline
// ---------------------------------------------------------------------------

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({
    required this.offline,
    required this.downloading,
    required this.progress,
    required this.available,
    required this.onDownload,
    required this.onClear,
  });

  final bool offline;
  final bool downloading;
  final double progress;
  final bool available;
  final VoidCallback onDownload;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offline ? kPrimary.withValues(alpha: 0.5) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                offline ? Icons.cloud_done : Icons.cloud_download_outlined,
                color: offline ? kPrimary : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.offlineTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (offline)
                _Pill(
                  icon: Icons.check,
                  label: context.l10n.offlineSaved,
                  background: kPrimaryLight,
                  foreground: kPrimaryDark,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            offline
                ? context.l10n.offlineSavedDesc
                : context.l10n.offlineDownloadDesc,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
          ),
          if (!available) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.offlineUnavailable,
              style: TextStyle(fontSize: 11.5, color: Colors.orange.shade800),
            ),
          ],
          if (downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(kPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.offlineDownloading('${(progress * 100).round()}'),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (offline)
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: Text(context.l10n.offlineDeleteMaps),
                  )
                else
                  FilledButton.icon(
                    onPressed: available ? onDownload : null,
                    icon: const Icon(Icons.download, size: 17),
                    label: Text(context.l10n.offlineDownloadMap),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Planeamento do passeio
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.saving,
    required this.weather,
    required this.weatherLoading,
    required this.weatherError,
    required this.bestDays,
    required this.prepReady,
    required this.onPickDate,
    required this.onSelectDay,
    required this.onGroupSize,
    required this.onTransport,
    required this.onToggleItem,
    required this.onSave,
  });

  final HikePlan? plan;
  final bool saving;
  final ScoredWeather? weather;
  final bool weatherLoading;
  final String? weatherError;
  final List<ScoredWeather> bestDays;
  final bool prepReady;
  final VoidCallback onPickDate;
  final ValueChanged<ScoredWeather> onSelectDay;
  final ValueChanged<int> onGroupSize;
  final ValueChanged<String> onTransport;
  final void Function(String item, bool value) onToggleItem;
  final VoidCallback onSave;

  String _dateLabel(BuildContext context, DateTime? date) {
    if (date == null) return context.l10n.planPickDate;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    if (p == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_calendar, color: kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.planTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (prepReady)
                _Pill(
                  icon: Icons.bolt,
                  label: context.l10n.planPrepBadge,
                  background: kPrimaryLight,
                  foreground: kPrimaryDark,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_dateLabel(context, p.date)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.planLessPeople,
                      onPressed: p.groupSize > 1 ? () => onGroupSize(p.groupSize - 1) : null,
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '${p.groupSize}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: context.l10n.planMorePeople,
                      onPressed: p.groupSize < 20 ? () => onGroupSize(p.groupSize + 1) : null,
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WeatherBlock(
            weather: weather,
            loading: weatherLoading,
            error: weatherError,
            bestDays: bestDays,
            hasDate: p.date != null,
            onSelectDay: onSelectDay,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: kTransportOptions.contains(p.transport)
                ? p.transport
                : 'car',
            decoration: InputDecoration(
              labelText: context.l10n.planHowGo,
              prefixIcon: const Icon(Icons.directions_bus_outlined),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: kTransportOptions
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(transportLabel(context, id)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onTransport(value);
            },
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.planChecklist('${p.checkedCount}', '${p.checklist.length}'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          ...p.checklist.entries.map(
            (entry) => CheckboxListTile(
              value: entry.value,
              onChanged: (value) => onToggleItem(entry.key, value ?? false),
              title: Text(
                planChecklistLabel(context, entry.key),
                style: const TextStyle(fontSize: 13.5),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(context.l10n.planSave),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.planLocalNote,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _WeatherBlock extends StatelessWidget {
  const _WeatherBlock({
    required this.weather,
    required this.loading,
    required this.error,
    required this.bestDays,
    required this.hasDate,
    required this.onSelectDay,
  });

  final ScoredWeather? weather;
  final bool loading;
  final String? error;
  final List<ScoredWeather> bestDays;
  final bool hasDate;
  final ValueChanged<ScoredWeather> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final current = weather;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasDate)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KumpasPalette.forestLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_cloudy, size: 18, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.forecastPickDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          )
        else if (loading)
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.forecastLoading,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          )
        else if (error != null)
          Row(
            children: [
              Icon(Icons.cloud_off, size: 17, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.forecastUnavailable,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            ],
          )
        else if (current != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: weatherRatingColor(current.rating).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: weatherRatingColor(current.rating).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      weatherIcon(current.weathercode),
                      color: weatherRatingColor(current.rating),
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${localizedWeatherLabel(context, current.label)} · ${current.tempMax.round()}° / ${current.tempMin.round()}°',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            // gen_l10n: ordem alfabética (date, rain, wind).
                        context.l10n.forecastRainWind(
                          current.date,
                          '${current.precipProb}',
                          '${current.windMax.round()}',
                        ),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: weatherRatingColor(current.rating),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        current.rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  current.reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                ),
                if (current.advice.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: current.advice
                        .map(
                          (tip) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        if (bestDays.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.forecastBestDays,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bestDays
                .map(
                  (day) => ActionChip(
                    avatar: Icon(
                      weatherIcon(day.weathercode),
                      size: 15,
                      color: weatherRatingColor(day.rating),
                    ),
                    label: Text(
                      '${day.dateTime == null ? day.date : shortWeekday(day.dateTime!, context.l10n.localeName)} · ${day.tempMax.round()}° · ${day.rating}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => onSelectDay(day),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Checkpoints
// ---------------------------------------------------------------------------

class _CheckpointTimeline extends StatelessWidget {
  const _CheckpointTimeline({
    required this.checkpoints,
    required this.unlocked,
    required this.loadingId,
    required this.onValidate,
  });

  final List<Checkpoint> checkpoints;
  final Set<String> unlocked;
  final String? loadingId;
  final ValueChanged<Checkpoint> onValidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < checkpoints.length; i++)
          _CheckpointRow(
            checkpoint: checkpoints[i],
            unlocked: unlocked.contains(checkpoints[i].id),
            loading: loadingId == checkpoints[i].id,
            isLast: i == checkpoints.length - 1,
            onValidate: () => onValidate(checkpoints[i]),
          ),
      ],
    );
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({
    required this.checkpoint,
    required this.unlocked,
    required this.loading,
    required this.isLast,
    required this.onValidate,
  });

  final Checkpoint checkpoint;
  final bool unlocked;
  final bool loading;
  final bool isLast;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final nodeColor = unlocked ? KumpasPalette.forest : KumpasPalette.line;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha do tempo
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: unlocked ? KumpasPalette.forest : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: Center(
                    child: unlocked
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '${checkpoint.order}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: KumpasPalette.muted,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: nodeColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: unlocked
                      ? KumpasPalette.forest.withValues(alpha: 0.35)
                      : KumpasPalette.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checkpoint.hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        checkpoint.imageUrl!,
                        width: double.infinity,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          checkpoint.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: KumpasPalette.ink,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (unlocked)
                        const Icon(
                          Icons.lock_open,
                          size: 18,
                          color: KumpasPalette.forest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked
                        ? checkpoint.lore
                        : context.l10n.checkpointLocked,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: unlocked
                          ? KumpasPalette.ink
                          : KumpasPalette.muted,
                      fontStyle: unlocked ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                  if (unlocked && checkpoint.loreSource != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.loreSource(checkpoint.loreSource ?? ''),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: KumpasPalette.forestDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.radar,
                        size: 14,
                        color: KumpasPalette.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.checkpointRadius('${checkpoint.radiusMeters}'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: KumpasPalette.muted,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: (loading || unlocked) ? null : onValidate,
                        icon: loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                unlocked ? Icons.verified : Icons.my_location,
                                size: 17,
                              ),
                        label: Text(unlocked ? context.l10n.checkpointDone : context.l10n.checkpointValidate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recompensas e reviews
// ---------------------------------------------------------------------------

class _RewardTeaser extends StatelessWidget {
  const _RewardTeaser();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KumpasPalette.amberSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KumpasPalette.amber.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: KumpasPalette.amber, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rewardTitle,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: KumpasPalette.amberDeep,
                  ),
                ),
                Text(
                  context.l10n.rewardBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: KumpasPalette.amberDeep.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: KumpasPalette.amber, size: 20),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.detail, required this.onReview});

  final QuestDetail detail;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final quest = detail.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StarRating(
              rating: quest.ratingAvg,
              showValue: true,
              count: quest.ratingCount,
              size: 20,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(
                detail.userReview == null ? context.l10n.reviewRate : context.l10n.reviewEdit,
              ),
            ),
          ],
        ),
        if (detail.reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.l10n.reviewEmpty,
              style: const TextStyle(color: KumpasPalette.muted, fontSize: 13),
            ),
          )
        else
          ...detail.reviews.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
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
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: kPrimaryLight,
                        child: Text(
                          r.userName.isEmpty ? '?' : r.userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: kPrimaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      StarRating(rating: r.rating.toDouble(), size: 13),
                    ],
                  ),
                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.comment!,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de review (só recolhe input; a API é chamada pelo ecrã pai)
// ---------------------------------------------------------------------------

class _ReviewResult {
  const _ReviewResult({required this.rating, required this.comment});

  final int rating;
  final String comment;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.initialRating, this.initialComment});

  final int initialRating;
  final String? initialComment;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _commentController =
      TextEditingController(text: widget.initialComment ?? '');

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reviewSheetTitle,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: KumpasPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.reviewSheetHint,
            style: const TextStyle(color: KumpasPalette.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  _rating >= i + 1
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 36,
                  color: KumpasPalette.amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.reviewComment,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0
                  ? null
                  : () => Navigator.of(context).pop(
                        _ReviewResult(
                          rating: _rating,
                          comment: _commentController.text,
                        ),
                      ),
              child: Text(context.l10n.reviewPublish),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trilha ao vivo + recados
// ---------------------------------------------------------------------------

class _LiveTrailCard extends StatelessWidget {
  const _LiveTrailCard({
    required this.session,
    required this.completed,
    required this.onStart,
  });

  final LiveSession? session;
  final bool completed;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final active = session != null;
    final minutes = active
        ? DateTime.now().difference(session!.startedAt).inMinutes
        : 0;
    final distanceKm = active ? session!.distanceMeters / 1000 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KumpasPalette.forestDark, KumpasPalette.forest],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: KumpasPalette.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active
                          ? context.l10n.liveInProgress
                          : completed
                              ? context.l10n.liveRerun
                              : context.l10n.liveTitle,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      active
                          ? context.l10n.liveStats('$minutes', distanceKm.toStringAsFixed(2))
                          : context.l10n.liveSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: KumpasPalette.forestDark,
              ),
              icon: Icon(active ? Icons.play_arrow : Icons.navigation),
              label: Text(active ? context.l10n.liveResume : context.l10n.liveStart),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesPreview extends StatelessWidget {
  const _MessagesPreview({required this.messages, required this.onOpen});

  final List<TrailMessage> messages;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KumpasPalette.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_outlined, color: KumpasPalette.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.messagesEmptyPreview,
                style: const TextStyle(fontSize: 12.5, color: KumpasPalette.muted),
              ),
            ),
            TextButton(onPressed: onOpen, child: Text(context.l10n.messagesStart)),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...messages.take(2).map(
              (message) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KumpasPalette.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (message.category) {
                        'perigo' => Icons.dangerous_outlined,
                        'aviso' => Icons.warning_amber,
                        _ => Icons.tips_and_updates_outlined,
                      },
                      size: 17,
                      color: switch (message.category) {
                        'perigo' => KumpasPalette.danger,
                        'aviso' => KumpasPalette.amber,
                        _ => KumpasPalette.forest,
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: KumpasPalette.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${message.userName} · 👍 ${message.likeCount}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: KumpasPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.map_outlined, size: 17),
            label: Text(
              messages.length > 2
                  ? context.l10n.messagesSeeAll('${messages.length}')
                  : context.l10n.messagesSee,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Auxiliares
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: KumpasPalette.muted,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: KumpasPalette.amberSoft,
              borderRadius: BorderRadius.circular(KumpasRadius.pill),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KumpasPalette.amberDeep,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CompassRose(size: 84),
            const SizedBox(height: 14),
            Text(
              context.l10n.detailError,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: KumpasPalette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KumpasPalette.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
