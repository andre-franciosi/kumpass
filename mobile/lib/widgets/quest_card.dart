import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/mapped_strings.dart';
import '../models/models.dart';
import '../theme/kumpas_theme.dart';
import 'ui.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    this.offline = false,
  });

  final QuestSummary quest;
  final VoidCallback onTap;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(quest: quest, offline: offline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: KumpasPalette.ink,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: StarRating(
                          rating: quest.ratingAvg,
                          showValue: true,
                          count: quest.ratingCount,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    quest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KumpasPalette.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _Meta(icon: Icons.straighten, text: '${quest.distanceKm} km'),
                      _Meta(
                        icon: Icons.schedule,
                        text: formatDuration(quest.durationMin),
                      ),
                      _Meta(
                        icon: Icons.trending_up,
                        text: '${quest.elevationGainM} m D+',
                      ),
                      _Meta(icon: Icons.bolt, text: '${quest.xpReward} XP'),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: quest.progress,
                            minHeight: 7,
                            backgroundColor: KumpasPalette.paperDark,
                            valueColor: const AlwaysStoppedAnimation(
                              KumpasPalette.forest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${quest.unlockedCount}/${quest.checkpointCount} checkpoints',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: KumpasPalette.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusPill(quest: quest),
                      const Spacer(),
                      Text(
                        quest.isCompleted
                            ? context.l10n.ctaReview
                            : quest.isActive
                                ? context.l10n.ctaContinue
                                : context.l10n.ctaView,
                        style: const TextStyle(
                          color: KumpasPalette.forestDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: KumpasPalette.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.quest, required this.offline});

  final QuestSummary quest;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (quest.imageUrl != null)
            Image.network(
              quest.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _CoverFallback(),
            )
          else
            const _CoverFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Row(
              children: [
                _GlassPill(
                  icon: Icons.place,
                  label: localizedRegion(context, quest.region),
                ),
                if (offline) ...[
                  const SizedBox(width: 6),
                  _GlassPill(
                    icon: Icons.cloud_done,
                    label: context.l10n.offlineBadge,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: DifficultyBadge(
              level: quest.difficulty,
              label: quest.difficultyLabel,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(KumpasRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KumpasPalette.forestDark, Color(0xFF4E8B57)],
        ),
      ),
      child: Center(
        child: Icon(Icons.terrain, color: Colors.white24, size: 64),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: KumpasPalette.amber),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: KumpasPalette.ink,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.quest});

  final QuestSummary quest;

  @override
  Widget build(BuildContext context) {
    final completed = quest.isCompleted;
    final active = quest.isActive;
    final color = completed
        ? KumpasPalette.forest
        : active
            ? KumpasPalette.sky
            : KumpasPalette.muted;
    final label = completed
        ? context.l10n.statusCompleted
        : active
            ? context.l10n.statusInProgress
            : context.l10n.statusNew;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KumpasRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed
                ? Icons.verified
                : active
                    ? Icons.play_circle
                    : Icons.explore,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
