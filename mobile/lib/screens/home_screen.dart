import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n.dart';
import '../l10n/mapped_strings.dart';
import '../map_style.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/language_store.dart';
import '../services/map_cache.dart';
import '../theme/kumpas_theme.dart';
import '../widgets/compass_rose.dart';
import '../widgets/quest_card.dart';
import 'trail_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.locale,
    required this.onLocaleChanged,
  });

  final KumpasUser user;
  final VoidCallback onLogout;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late final TileProvider? _tileProvider = MapCache.createTileProvider();

  UserProfile? _profile;
  List<QuestSummary> _quests = const [];
  Set<String> _offlineIds = {};
  bool _loading = true;
  String? _error;
  String _region = 'Todas';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _profile == null;
      _error = null;
    });

    try {
      final results = await Future.wait<Object>([
        _api.getProfile(widget.user.id),
        _api.getQuests(widget.user.id, lang: widget.locale.languageCode),
      ]);

      final quests = results[1] as List<QuestSummary>;
      final offlineFlags = await Future.wait(
        quests.map((quest) => MapCache.isOffline(quest.id)),
      );

      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _quests = quests;
        _offlineIds = {
          for (var i = 0; i < quests.length; i++)
            if (offlineFlags[i]) quests[i].id,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> get _regions {
    final regions = _quests.map((q) => q.region).toSet().toList()..sort();
    return ['Todas', ...regions];
  }

  List<QuestSummary> get _filtered =>
      _region == 'Todas'
          ? _quests
          : _quests.where((q) => q.region == _region).toList();

  Future<void> _openQuest(QuestSummary quest) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrailDetailScreen(
          user: widget.user,
          questId: quest.id,
          initial: quest,
          localeCode: widget.locale.languageCode,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CompassRose(size: 26),
            SizedBox(width: 10),
            Text('Kumpas'),
          ],
        ),
        actions: [
          LanguageButton(
            locale: widget.locale,
            onChanged: widget.onLocaleChanged,
          ),
          IconButton(
            tooltip: context.l10n.refresh,
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: context.l10n.logout,
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null && _quests.isEmpty
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        if (_profile != null) _ProfileHeader(profile: _profile!),
                        const SizedBox(height: 16),
                        _RegionMap(
                          quests: _filtered,
                          onQuestTap: _openQuest,
                          tileProvider: _tileProvider,
                        ),
                        const SizedBox(height: 16),
                        _RegionFilter(
                          regions: _regions,
                          selected: _region,
                          onSelected: (r) => setState(() => _region = r),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.l10n.trails,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: KumpasPalette.ink,
                                height: 1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              context.l10n.trailsAvailable(_filtered.length),
                              style: const TextStyle(
                                color: KumpasPalette.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                const CompassRose(size: 72),
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.emptyRegion,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._filtered.map(
                            (q) => QuestCard(
                              quest: q,
                              offline: _offlineIds.contains(q.id),
                              onTap: () => _openQuest(q),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho de gamificação
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.user.name.split(' ').first;
    final remaining = profile.xpForNextLevel - profile.xpIntoLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _XpRing(progress: profile.levelProgress, level: profile.level),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.homeGreeting(firstName),
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KumpasPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // gen_l10n: placeholders por ordem alfabética (count, xp).
                        context.l10n.homeXpCheckpoints(
                          profile.unlockedCheckpoints,
                          profile.xp,
                        ),
                        style: const TextStyle(
                          color: KumpasPalette.muted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        // gen_l10n: placeholders por ordem alfabética (level, remaining).
                        context.l10n.homeXpToNextLevel(
                          profile.level + 1,
                          remaining,
                        ),
                        style: const TextStyle(
                          color: KumpasPalette.amberDeep,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: KumpasPalette.amberSoft,
                    borderRadius: BorderRadius.circular(KumpasRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: KumpasPalette.amber, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.completedQuests}/${profile.totalQuests}',
                        style: const TextStyle(
                          color: KumpasPalette.amberDeep,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (profile.badges.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: profile.badges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) =>
                      _BadgeChip(badge: profile.badges[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _XpRing extends StatelessWidget {
  const _XpRing({required this.progress, required this.level});

  final double progress;
  final int level;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 58,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CircularProgressIndicator(
            value: 1,
            strokeWidth: 6,
            color: KumpasPalette.paperDark,
            strokeCap: StrokeCap.round,
          ),
          CircularProgressIndicator(
            value: progress.clamp(0.02, 1.0),
            strokeWidth: 6,
            color: KumpasPalette.amber,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.levelShort,
                  style: const TextStyle(
                    fontSize: 9,
                    color: KumpasPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$level',
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: KumpasPalette.forestDark,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: KumpasPalette.forestLight,
          borderRadius: BorderRadius.circular(KumpasRadius.pill),
          border: Border.all(color: KumpasPalette.forest.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(badge.icon), size: 14, color: KumpasPalette.amber),
            const SizedBox(width: 5),
            Text(
              localizedBadgeTitle(context, badge.title, badge.icon),
              style: const TextStyle(
                color: KumpasPalette.forestDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'footsteps':
        return Icons.directions_walk;
      case 'terrain':
        return Icons.terrain;
      case 'collections_bookmark':
        return Icons.collections_bookmark;
      case 'shield':
        return Icons.shield;
      case 'rate_review':
        return Icons.rate_review;
      case 'wb_sunny':
        return Icons.wb_sunny;
      default:
        return Icons.military_tech;
    }
  }
}

// ---------------------------------------------------------------------------
// Mapa da região
// ---------------------------------------------------------------------------

class _RegionMap extends StatelessWidget {
  const _RegionMap({
    required this.quests,
    required this.onQuestTap,
    required this.tileProvider,
  });

  final List<QuestSummary> quests;
  final ValueChanged<QuestSummary> onQuestTap;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.mapRegion,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: KumpasPalette.muted,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.tapPin,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KumpasPalette.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 320,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(38.72, -9.2),
                initialZoom: 9.2,
                minZoom: 7,
                maxZoom: 17,
                backgroundColor: KumpasPalette.mapCanvas,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: kMapTileUrl,
                  userAgentPackageName: kMapUserAgent,
                  tileProvider: tileProvider,
                  maxNativeZoom: MapCache.maxNativeZoom,
                  errorTileCallback: MapCache.noteTileError,
                ),
                MarkerLayer(
                  markers: quests
                      .map(
                        (q) => Marker(
                          point: q.center.latLng,
                          width: 170,
                          height: 66,
                          child: _QuestPin(quest: q, onTap: () => onQuestTap(q)),
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

class _QuestPin extends StatelessWidget {
  const _QuestPin({required this.quest, required this.onTap});

  final QuestSummary quest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = quest.isCompleted
        ? KumpasPalette.forest
        : quest.isActive
            ? KumpasPalette.sky
            : KumpasPalette.muted;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KumpasRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                    quest.isCompleted
                        ? Icons.verified
                        : quest.isActive
                            ? Icons.play_arrow
                            : Icons.terrain,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    quest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: KumpasPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, color: color, size: 22),
        ],
      ),
    );
  }
}

class _RegionFilter extends StatelessWidget {
  const _RegionFilter({
    required this.regions,
    required this.selected,
    required this.onSelected,
  });

  final List<String> regions;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: regions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final region = regions[index];
          final isSelected = region == selected;
          return ChoiceChip(
            label: Text(
              region == 'Todas'
                  ? context.l10n.allRegions
                  : localizedRegion(context, region),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(region),
            side: BorderSide(
              color: isSelected ? KumpasPalette.forest : KumpasPalette.line,
            ),
            selectedColor: KumpasPalette.forestLight,
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 64),
        const Center(child: CompassRose(size: 84)),
        const SizedBox(height: 18),
        Text(
          context.l10n.loadRegionError,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KumpasPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: KumpasPalette.muted),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.retry),
          ),
        ),
      ],
    );
  }
}
