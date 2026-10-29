import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? kApiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        (data['message'] as String?) ?? 'Erro ${response.statusCode}.',
      );
    }
    return data;
  }

  Future<KumpasUser> login({required String email, String? name}) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, if (name != null) 'name': name}),
    );
    return KumpasUser.fromJson(_decode(response));
  }

  Future<List<QuestSummary>> getQuests(
    String userId, {
    String lang = 'pt',
  }) async {
    final response = await _client.get(
      _uri('/api/quests', {'userId': userId, 'lang': lang}),
    );
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException('Não foi possível carregar as trilhas.');
    }
    return data
        .map((e) => QuestSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuestDetail> getQuest(
    String questId,
    String userId, {
    String lang = 'pt',
  }) async {
    final response = await _client.get(
      _uri('/api/quests/$questId', {'userId': userId, 'lang': lang}),
    );
    return QuestDetail.fromJson(_decode(response));
  }

  Future<UserProfile> getProfile(String userId) async {
    final response = await _client.get(_uri('/api/users/$userId/profile'));
    return UserProfile.fromJson(_decode(response));
  }

  Future<UnlockResult> unlockCheckpoint({
    required String userId,
    required String checkpointId,
    required double userLat,
    required double userLng,
    String lang = 'pt',
  }) async {
    final response = await _client.post(
      _uri('/api/checkpoints/unlock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'checkpointId': checkpointId,
        'userLat': userLat,
        'userLng': userLng,
        'lang': lang,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      final lore = data['lore'] as Map<String, dynamic>?;
      final quest = data['quest'] as Map<String, dynamic>?;
      return UnlockResult(
        success: true,
        message: 'Checkpoint validado!',
        title: lore?['title'] as String?,
        content: lore?['content'] as String?,
        source: lore?['source'] as String?,
        xpGained: data['xpGained'] as int? ?? 0,
        questCompleted: quest?['completed'] as bool? ?? false,
        unlockedCount: quest?['unlockedCount'] as int? ?? 0,
        totalCheckpoints: quest?['totalCheckpoints'] as int? ?? 0,
      );
    }

    return UnlockResult(
      success: false,
      message: (data['message'] as String?) ?? 'Não foi possível validar.',
    );
  }

  Future<Review> submitReview({
    required String questId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post(
      _uri('/api/quests/$questId/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      }),
    );
    return Review.fromJson(_decode(response));
  }

  Future<ScoredWeather> getWeather({
    required double lat,
    required double lng,
    required String date,
    String lang = 'pt',
  }) async {
    final response = await _client.get(
      _uri('/api/weather', {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'date': date,
        'lang': lang,
      }),
    );
    final data = _decode(response);
    return ScoredWeather.fromJson(
      (data['weather'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<List<ScoredWeather>> getBestDays(
    String questId, {
    String lang = 'pt',
  }) async {
    final response = await _client.get(
      _uri('/api/quests/$questId/best-days', {'lang': lang}),
    );
    final data = _decode(response);
    return ((data['days'] as List<dynamic>?) ?? const [])
        .map((e) => ScoredWeather.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrailMessage>> getMessages(
    String questId,
    String userId,
  ) async {
    final response = await _client.get(
      _uri('/api/quests/$questId/messages', {'userId': userId}),
    );
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException('Não foi possível carregar os recados.');
    }
    return data
        .map((e) => TrailMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrailMessage> postMessage({
    required String questId,
    required String userId,
    required String category,
    required String text,
    required double lat,
    required double lng,
  }) async {
    final response = await _client.post(
      _uri('/api/quests/$questId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'category': category,
        'text': text,
        'lat': lat,
        'lng': lng,
      }),
    );
    return TrailMessage.fromJson(_decode(response));
  }

  Future<({bool liked, int likeCount})> toggleMessageLike(
    String messageId,
    String userId,
  ) async {
    final response = await _client.post(
      _uri('/api/messages/$messageId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    final data = _decode(response);
    return (
      liked: data['liked'] as bool? ?? false,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  Future<void> reportMessage(String messageId, String userId) async {
    final response = await _client.post(
      _uri('/api/messages/$messageId/report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    _decode(response);
  }
}
