import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Tradução de valores que chegam da API em português (dificuldade, clima,
/// badges, categorias de recado). O conteúdo editorial (lore, descrições,
/// reviews) mantém-se no idioma de origem.
String localizedDifficulty(BuildContext context, int level) {
  final l10n = context.l10n;
  return switch (level) {
    1 => l10n.difficulty1,
    2 => l10n.difficulty2,
    3 => l10n.difficulty3,
    4 => l10n.difficulty4,
    _ => l10n.difficulty5,
  };
}

/// Nota: o gen_l10n ordena os placeholders alfabeticamente — `label` primeiro.
String localizedDifficultyTitle(
  BuildContext context,
  int level,
  String label,
) =>
    context.l10n.difficultyTitle(
      _difficultyLabelFrom(context, level, label),
      level,
    );

String _difficultyLabelFrom(BuildContext context, int level, String fallback) {
  // Preferimos sempre o mapa local (a API pode enviar PT).
  return localizedDifficulty(context, level).isNotEmpty
      ? localizedDifficulty(context, level)
      : fallback;
}

String localizedWeatherRating(BuildContext context, String rating) {
  final l10n = context.l10n;
  return switch (rating) {
    'Ideal' => l10n.weatherIdeal,
    'Bom' => l10n.weatherGood,
    'Evitar' => l10n.weatherAvoid,
    _ => rating,
  };
}

String localizedWeatherLabel(BuildContext context, String label) {
  final l10n = context.l10n;
  return switch (label) {
    'Céu limpo' => l10n.weatherClear,
    'Pouco nublado' => l10n.weatherMostlyClear,
    'Nublado' => l10n.weatherCloudy,
    'Nevoeiro' => l10n.weatherFog,
    'Chuvisco' => l10n.weatherDrizzle,
    'Chuva' => l10n.weatherRain,
    'Neve' => l10n.weatherSnow,
    'Aguaceiros' => l10n.weatherShowers,
    'Trovoada' => l10n.weatherThunderstorm,
    'Condições variáveis' => l10n.weatherVariable,
    _ => label,
  };
}

String localizedBadgeTitle(BuildContext context, String title, String icon) {
  final l10n = context.l10n;
  if (title.startsWith('Guardião de ')) {
    return l10n.badgeGuardian(title.replaceFirst('Guardião de ', ''));
  }
  return switch (title) {
    'Primeiro Passo' => l10n.badgeFirstStep,
    'Explorador' => l10n.badgeExplorer,
    'Colecionador de Histórias' => l10n.badgeCollector,
    'Voz da Montanha' => l10n.badgeVoice,
    'Caçador de Sol' => l10n.badgeSunChaser,
    _ => title,
  };
}

String localizedError(BuildContext context, String raw) {
  final message = raw.replaceFirst('Exception: ', '');
  return switch (message) {
    'location-disabled' => context.l10n.locationDisabled,
    'location-denied' => context.l10n.locationDenied,
    _ => message,
  };
}

String transportLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'walk' => l10n.transportWalk,
    'car' => l10n.transportCar,
    'train' => l10n.transportTrain,
    'bus' => l10n.transportBus,
    _ => id,
  };
}

/// Nomes de região com acentuação correta (a API usa chaves sem acento).
String localizedRegion(BuildContext context, String region) {
  return switch (region) {
    'Arrabida' => 'Arrábida',
    _ => region,
  };
}

String planChecklistLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'water' => l10n.planChecklistWater,
    'snacks' => l10n.planChecklistSnacks,
    'battery' => l10n.planChecklistBattery,
    'shoes' => l10n.planChecklistShoes,
    'sun' => l10n.planChecklistSun,
    _ => id,
  };
}

String localizedMessageCategory(BuildContext context, String category) {
  final l10n = context.l10n;
  return switch (category) {
    'dica' => l10n.catTip,
    'aviso' => l10n.catWarning,
    'perigo' => l10n.catDanger,
    _ => category,
  };
}
