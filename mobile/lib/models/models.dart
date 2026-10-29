import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

class KumpasUser {
  const KumpasUser({
    required this.id,
    required this.email,
    required this.name,
    this.isTest = false,
  });

  final String id;
  final String email;
  final String name;

  /// Conta de demonstração: permite simular o GPS em qualquer lugar.
  final bool isTest;

  factory KumpasUser.fromJson(Map<String, dynamic> json) => KumpasUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        isTest: json['isTest'] as bool? ?? false,
      );
}

class TrailMessage {
  const TrailMessage({
    required this.id,
    required this.category,
    required this.text,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.likeCount,
    required this.userName,
    required this.likedByMe,
  });

  final String id;
  final String category;
  final String text;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final int likeCount;
  final String userName;
  final bool likedByMe;

  LatLng get latLng => LatLng(lat, lng);

  factory TrailMessage.fromJson(Map<String, dynamic> json) => TrailMessage(
        id: json['id'] as String,
        category: json['category'] as String,
        text: json['text'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        likeCount: json['likeCount'] as int? ?? 0,
        userName: json['userName'] as String? ?? 'Explorador',
        likedByMe: json['likedByMe'] as bool? ?? false,
      );

  TrailMessage copyWith({int? likeCount, bool? likedByMe}) => TrailMessage(
        id: id,
        category: category,
        text: text,
        lat: lat,
        lng: lng,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        userName: userName,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}

class RegionCenter {
  const RegionCenter({required this.lat, required this.lng});

  final double lat;
  final double lng;

  LatLng get latLng => LatLng(lat, lng);

  factory RegionCenter.fromJson(Map<String, dynamic> json) => RegionCenter(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

class MapBounds {
  const MapBounds({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  RegionCenter get center => RegionCenter(
        lat: (minLat + maxLat) / 2,
        lng: (minLng + maxLng) / 2,
      );

  LatLngBounds get latLngBounds => LatLngBounds(
        LatLng(maxLat, maxLng),
        LatLng(minLat, minLng),
      );

  factory MapBounds.fromJson(Map<String, dynamic> json) => MapBounds(
        minLat: (json['minLat'] as num).toDouble(),
        minLng: (json['minLng'] as num).toDouble(),
        maxLat: (json['maxLat'] as num).toDouble(),
        maxLng: (json['maxLng'] as num).toDouble(),
      );
}

class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.order,
    required this.title,
    required this.lore,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    this.loreSource,
    this.loreUrl,
    this.imageUrl,
    this.imageCredit,
  });

  final String id;
  final int order;
  final String title;
  final String lore;
  final String? loreSource;
  final String? loreUrl;
  final String? imageUrl;
  final String? imageCredit;
  final double lat;
  final double lng;
  final int radiusMeters;

  /// História com fonte real (Wikipédia/curadoria), não genérica.
  bool get hasRealLore => loreSource != null && loreSource != 'Fallback';

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  LatLng get latLng => LatLng(lat, lng);

  factory Checkpoint.fromJson(Map<String, dynamic> json) => Checkpoint(
        id: json['id'] as String,
        order: json['order'] as int,
        title: json['title'] as String,
        lore: json['lore'] as String,
        loreSource: json['loreSource'] as String?,
        loreUrl: json['loreUrl'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageCredit: json['imageCredit'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        radiusMeters: json['radiusMeters'] as int,
      );
}

class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.userName,
    this.comment,
    this.updatedAt,
  });

  final String id;
  final int rating;
  final String userName;
  final String? comment;
  final DateTime? updatedAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        rating: json['rating'] as int,
        userName: json['userName'] as String? ?? 'Explorador',
        comment: json['comment'] as String?,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

class DifficultyBreakdown {
  const DifficultyBreakdown({
    required this.distanceKm,
    required this.durationMin,
    required this.elevationGainM,
    required this.checkpointCount,
    required this.terrainFactor,
    required this.score,
  });

  final double distanceKm;
  final int durationMin;
  final int elevationGainM;
  final int checkpointCount;
  final double terrainFactor;
  final double score;

  factory DifficultyBreakdown.fromJson(Map<String, dynamic> json) =>
      DifficultyBreakdown(
        distanceKm: (json['distanceKm'] as num).toDouble(),
        durationMin: json['durationMin'] as int,
        elevationGainM: json['elevationGainM'] as int,
        checkpointCount: json['checkpointCount'] as int,
        terrainFactor: (json['terrainFactor'] as num).toDouble(),
        score: (json['score'] as num).toDouble(),
      );
}

class QuestSummary {
  const QuestSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.checkpointCount,
    required this.distanceKm,
    required this.durationMin,
    required this.elevationGainM,
    required this.difficulty,
    required this.difficultyLabel,
    required this.difficultyScore,
    required this.xpReward,
    required this.ratingAvg,
    required this.ratingCount,
    required this.center,
    required this.status,
    required this.unlockedCount,
    this.bbox,
    this.imageUrl,
    this.imageCredit,
  });

  final String id;
  final String title;
  final String description;
  final String region;
  final String? imageUrl;
  final String? imageCredit;
  final int checkpointCount;
  final double distanceKm;
  final int durationMin;
  final int elevationGainM;
  final int difficulty;
  final String difficultyLabel;
  final double difficultyScore;
  final int xpReward;
  final double ratingAvg;
  final int ratingCount;
  final RegionCenter center;
  final MapBounds? bbox;
  final String status;
  final int unlockedCount;

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';

  double get progress =>
      checkpointCount == 0 ? 0 : unlockedCount / checkpointCount;

  factory QuestSummary.fromJson(Map<String, dynamic> json) {
    final userStatus =
        (json['userStatus'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return QuestSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      region: json['region'] as String,
      imageUrl: json['imageUrl'] as String?,
      imageCredit: json['imageCredit'] as String?,
      checkpointCount: json['checkpointCount'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      durationMin: json['durationMin'] as int? ?? 0,
      elevationGainM: json['elevationGainM'] as int? ?? 0,
      difficulty: json['difficulty'] as int? ?? 1,
      difficultyLabel: json['difficultyLabel'] as String? ?? 'Fácil',
      difficultyScore: (json['difficultyScore'] as num? ?? 0).toDouble(),
      xpReward: json['xpReward'] as int? ?? 0,
      ratingAvg: (json['ratingAvg'] as num? ?? 0).toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
      center: RegionCenter.fromJson(
        (json['center'] as Map<String, dynamic>?) ?? const {'lat': 38.72, 'lng': -9.14},
      ),
      bbox: json['bbox'] is Map<String, dynamic>
          ? MapBounds.fromJson(json['bbox'] as Map<String, dynamic>)
          : null,
      status: userStatus['status'] as String? ?? 'not_started',
      unlockedCount: userStatus['unlockedCount'] as int? ?? 0,
    );
  }
}

class QuestDetail {
  const QuestDetail({
    required this.summary,
    required this.checkpoints,
    required this.reviews,
    required this.unlockedCheckpointIds,
    required this.breakdown,
    required this.track,
    this.userReview,
  });

  final QuestSummary summary;
  final List<Checkpoint> checkpoints;
  final List<Review> reviews;
  final Set<String> unlockedCheckpointIds;
  final DifficultyBreakdown breakdown;
  final List<LatLng> track;
  final Review? userReview;

  int get unlockedCount => unlockedCheckpointIds.length;

  factory QuestDetail.fromJson(Map<String, dynamic> json) {
    final reviewJson = json['userReview'] as Map<String, dynamic>?;

    return QuestDetail(
      summary: QuestSummary.fromJson(json),
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => Checkpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: ((json['reviews'] as List<dynamic>?) ?? const [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedCheckpointIds:
          ((json['unlockedCheckpointIds'] as List<dynamic>?) ?? const [])
              .map((e) => e as String)
              .toSet(),
      breakdown: DifficultyBreakdown.fromJson(
        (json['difficultyBreakdown'] as Map<String, dynamic>?) ?? const {},
      ),
      track: ((json['track'] as List<dynamic>?) ?? const [])
          .whereType<List<dynamic>>()
          .where((p) => p.length == 2)
          .map((p) => LatLng(
                (p[0] as num).toDouble(),
                (p[1] as num).toDouble(),
              ))
          .toList(),
      userReview: reviewJson == null ? null : Review.fromJson(reviewJson),
    );
  }
}

class ScoredWeather {
  const ScoredWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipProb,
    required this.windMax,
    required this.weathercode,
    required this.label,
    required this.score,
    required this.rating,
    required this.reason,
    required this.advice,
  });

  final String date;
  final double tempMax;
  final double tempMin;
  final int precipProb;
  final double windMax;
  final int weathercode;
  final String label;
  final int score;
  final String rating;
  final String reason;
  final List<String> advice;

  bool get isGood => rating == 'Ideal' || rating == 'Bom';

  DateTime? get dateTime => DateTime.tryParse(date);

  factory ScoredWeather.fromJson(Map<String, dynamic> json) => ScoredWeather(
        date: json['date'] as String,
        tempMax: (json['tempMax'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        precipProb: (json['precipProb'] as num).round(),
        windMax: (json['windMax'] as num).toDouble(),
        weathercode: json['weathercode'] as int? ?? 3,
        label: json['label'] as String? ?? 'Condições variáveis',
        score: json['score'] as int? ?? 0,
        rating: json['rating'] as String? ?? 'Bom',
        reason: json['reason'] as String? ?? '',
        advice: ((json['advice'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

class UserBadge {
  const UserBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String icon;

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'military_tech',
      );
}

class UserProfile {
  const UserProfile({
    required this.user,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.completedQuests,
    required this.totalQuests,
    required this.unlockedCheckpoints,
    required this.totalCheckpoints,
    required this.reviewsWritten,
    required this.badges,
  });

  final KumpasUser user;
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final int completedQuests;
  final int totalQuests;
  final int unlockedCheckpoints;
  final int totalCheckpoints;
  final int reviewsWritten;
  final List<UserBadge> badges;

  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : xpIntoLevel / xpForNextLevel;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        user: KumpasUser.fromJson(json['user'] as Map<String, dynamic>),
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        xpIntoLevel: json['xpIntoLevel'] as int? ?? 0,
        xpForNextLevel: json['xpForNextLevel'] as int? ?? 500,
        completedQuests: json['completedQuests'] as int? ?? 0,
        totalQuests: json['totalQuests'] as int? ?? 0,
        unlockedCheckpoints: json['unlockedCheckpoints'] as int? ?? 0,
        totalCheckpoints: json['totalCheckpoints'] as int? ?? 0,
        reviewsWritten: json['reviewsWritten'] as int? ?? 0,
        badges: ((json['badges'] as List<dynamic>?) ?? const [])
            .map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UnlockResult {
  const UnlockResult({
    required this.success,
    required this.message,
    this.title,
    this.content,
    this.source,
    this.xpGained = 0,
    this.questCompleted = false,
    this.unlockedCount = 0,
    this.totalCheckpoints = 0,
  });

  final bool success;
  final String message;
  final String? title;
  final String? content;
  final String? source;
  final int xpGained;
  final bool questCompleted;
  final int unlockedCount;
  final int totalCheckpoints;
}
