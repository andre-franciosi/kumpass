import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sessão de trilha ao vivo (para retomar após fechar a app).
class LiveSession {
  const LiveSession({
    required this.questId,
    required this.startedAt,
    this.distanceMeters = 0,
  });

  final String questId;
  final DateTime startedAt;
  final double distanceMeters;

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'startedAt': startedAt.toIso8601String(),
        'distanceMeters': distanceMeters,
      };

  factory LiveSession.fromJson(Map<String, dynamic> json) => LiveSession(
        questId: json['questId'] as String,
        startedAt:
            DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
        distanceMeters: (json['distanceMeters'] as num? ?? 0).toDouble(),
      );
}

class LiveSessionStore {
  static const String _key = 'kumpas_live_session';

  static Future<LiveSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return LiveSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(LiveSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Check-in feito sem rede, à espera de ser enviado ao servidor.
class PendingUnlock {
  const PendingUnlock({
    required this.questId,
    required this.checkpointId,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  final String questId;
  final String checkpointId;
  final double lat;
  final double lng;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'checkpointId': checkpointId,
        'lat': lat,
        'lng': lng,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingUnlock.fromJson(Map<String, dynamic> json) => PendingUnlock(
        questId: json['questId'] as String,
        checkpointId: json['checkpointId'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class PendingUnlockStore {
  static const String _key = 'kumpas_pending_unlocks';

  static Future<List<PendingUnlock>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((item) {
          try {
            return PendingUnlock.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingUnlock>()
        .toList();
  }

  static Future<void> add(PendingUnlock unlock) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final already = raw.any((item) {
      try {
        final parsed = PendingUnlock.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
        return parsed.checkpointId == unlock.checkpointId;
      } catch (_) {
        return false;
      }
    });
    if (already) return;
    raw.add(jsonEncode(unlock.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> remove(String checkpointId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final filtered = raw.where((item) {
      try {
        final parsed = PendingUnlock.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
        return parsed.checkpointId != checkpointId;
      } catch (_) {
        return false;
      }
    }).toList();
    await prefs.setStringList(_key, filtered);
  }
}
