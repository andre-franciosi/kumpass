/// Planeamento do passeio — persistência local no MVP.
///
/// A interface [PlanRepository] já está desenhada para o backend futuro:
/// quando existir `POST /api/plans` / `GET /api/plans?userId=`, basta criar
/// um `RemotePlanRepository implements PlanRepository` e injetá-lo na app.
/// Nenhum ecrã precisa de mudar.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HikePlan {
  HikePlan({
    required this.questId,
    required this.date,
    required this.groupSize,
    required this.transport,
    required this.checklist,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  final String questId;
  final DateTime? date;
  final int groupSize;
  final String transport;
  final Map<String, bool> checklist;
  final DateTime savedAt;

  bool get checklistCompleted =>
      checklist.isNotEmpty && checklist.values.every((v) => v);

  int get checkedCount => checklist.values.where((v) => v).length;

  /// XP simbólico por preparar o passeio (atribuído pela UI, não vale como XP real).
  int get prepXp => checklistCompleted ? 50 : 0;

  HikePlan copyWith({
    DateTime? date,
    int? groupSize,
    String? transport,
    Map<String, bool>? checklist,
  }) =>
      HikePlan(
        questId: questId,
        date: date ?? this.date,
        groupSize: groupSize ?? this.groupSize,
        transport: transport ?? this.transport,
        checklist: checklist ?? this.checklist,
        savedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'date': date?.toIso8601String(),
        'groupSize': groupSize,
        'transport': transport,
        'checklist': checklist,
        'savedAt': savedAt.toIso8601String(),
      };

  factory HikePlan.fromJson(Map<String, dynamic> json) => HikePlan(
        questId: json['questId'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        groupSize: json['groupSize'] as int? ?? 2,
        transport: normalizeTransport(
          json['transport'] as String? ?? 'car',
        ),
        checklist: normalizeChecklist(
          ((json['checklist'] as Map<String, dynamic>?) ?? const {})
              .map((key, value) => MapEntry(key, value as bool)),
        ),
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
      );
}

/// Transportes (ids estáveis; o rótulo é traduzido na UI).
const List<String> kTransportOptions = ['walk', 'car', 'train', 'bus'];

const Map<String, String> kLegacyTransportKeys = {
  'A pé': 'walk',
  'Carro': 'car',
  'Comboio': 'train',
  'Autocarro': 'bus',
};

String normalizeTransport(String transport) =>
    kLegacyTransportKeys[transport] ?? transport;

const List<String> kPlanChecklistItems = [
  'water',
  'snacks',
  'battery',
  'shoes',
  'sun',
];

/// Mapa das chaves antigas (PT) para os ids atuais.
const Map<String, String> kLegacyChecklistKeys = {
  'Água (1,5 L por pessoa)': 'water',
  'Snacks e fruta': 'snacks',
  'Bateria externa / telemóvel carregado': 'battery',
  'Calçado de trilho': 'shoes',
  'Proteção solar e chapéu': 'sun',
};

Map<String, bool> normalizeChecklist(Map<String, bool> checklist) => {
      for (final entry in checklist.entries)
        kLegacyChecklistKeys[entry.key] ?? entry.key: entry.value,
    };

abstract class PlanRepository {
  Future<HikePlan?> load(String questId);
  Future<void> save(HikePlan plan);
  Future<void> remove(String questId);
}

/// MVP: guarda no dispositivo (SharedPreferences), sobrevive ao fecho da app.
class LocalPlanRepository implements PlanRepository {
  LocalPlanRepository._();

  static final LocalPlanRepository instance = LocalPlanRepository._();

  static const String _keyPrefix = 'kumpas_hike_plan_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<HikePlan?> load(String questId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_keyPrefix$questId');
    if (raw == null) return null;
    try {
      return HikePlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(HikePlan plan) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_keyPrefix${plan.questId}',
      jsonEncode(plan.toJson()),
    );
  }

  @override
  Future<void> remove(String questId) async {
    final prefs = await _prefs;
    await prefs.remove('$_keyPrefix$questId');
  }
}

/// Reservado para a fase seguinte (backend). Mantém o contrato.
///
/// Exemplo de implementação futura:
/// ```dart
/// final response = await client.post(
///   Uri.parse('$baseUrl/api/plans'),
///   body: jsonEncode({'userId': userId, ...plan.toJson()}),
/// );
/// ```
class RemotePlanRepository implements PlanRepository {
  const RemotePlanRepository();

  @override
  Future<HikePlan?> load(String questId) =>
      throw UnsupportedError('POST /api/plans ainda não implementado.');

  @override
  Future<void> save(HikePlan plan) =>
      throw UnsupportedError('POST /api/plans ainda não implementado.');

  @override
  Future<void> remove(String questId) =>
      throw UnsupportedError('DELETE /api/plans/:questId ainda não implementado.');
}
