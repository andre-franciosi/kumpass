import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/mapped_strings.dart';
import '../theme/kumpas_theme.dart';

// Aliases herdados (mantêm os ecrãs atuais a compilar).
const Color kPrimary = KumpasPalette.forest;
const Color kPrimaryDark = KumpasPalette.forestDark;
const Color kPrimaryLight = KumpasPalette.forestLight;

Color difficultyColor(int level) {
  switch (level) {
    case 1:
      return const Color(0xFF3E8E4F);
    case 2:
      return const Color(0xFF7FA24A);
    case 3:
      return KumpasPalette.amber;
    case 4:
      return const Color(0xFFC4552B);
    default:
      return const Color(0xFF7A4E9E);
  }
}

IconData difficultyIcon(int level) {
  switch (level) {
    case 1:
      return Icons.directions_walk;
    case 2:
      return Icons.hiking;
    case 3:
      return Icons.terrain;
    case 4:
      return Icons.local_fire_department;
    default:
      return Icons.auto_awesome;
  }
}

String formatDuration(int minutes) {
  if (minutes <= 0) return '—';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}min';
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest.toString().padLeft(2, '0')}';
}

IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 2) return Icons.wb_cloudy;
  if (code == 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 67) return Icons.water_drop;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.water_drop;
  if (code >= 95) return Icons.thunderstorm;
  return Icons.cloud_queue;
}

Color weatherRatingColor(String rating) {
  switch (rating) {
    case 'Ideal':
      return KumpasPalette.forest;
    case 'Bom':
      return KumpasPalette.amber;
    default:
      return KumpasPalette.danger;
  }
}

String shortWeekday(DateTime date, String localeName) {
  final formatted = DateFormat('EEE, dd/MM', localeName).format(date);
  return formatted.replaceFirst('.,', ',');
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.level,
    required this.label,
    this.compact = false,
  });

  final int level;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KumpasRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(difficultyIcon(level), size: compact ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            localizedDifficultyTitle(context, level, label),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = false,
    this.count,
    this.valueColor,
  });

  final double rating;
  final double size;
  final bool showValue;
  final int? count;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final IconData icon;
          if (rating >= i + 1) {
            icon = Icons.star_rounded;
          } else if (rating >= i + 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(icon, size: size, color: KumpasPalette.amber);
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.w700,
              color: valueColor ?? KumpasPalette.ink,
            ),
          ),
        ],
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size - 3,
              color: valueColor?.withValues(alpha: 0.75) ?? KumpasPalette.muted,
            ),
          ),
        ],
      ],
    );
  }
}
