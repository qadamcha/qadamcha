import '../../domain/entities/child_entity.dart';

class ChildModel extends Child {
  const ChildModel({
    required super.id,
    required super.parentId,
    required super.name,
    required super.age,
    required super.gender,
    super.avatar,
    required super.limits,
    required super.todayUsage,
    required super.settings,
    required super.createdAt,
  });
  
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? json['_id'] ?? '',
      parentId: json['parentId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 3,
      gender: json['gender'] ?? 'boy',
      avatar: json['avatar'],
      limits: DailyLimitsModel.fromJson(json['limits'] ?? {}),
      todayUsage: UsageStatsModel.fromJson(json['todayUsage'] ?? {}),
      settings: ChildSettingsModel.fromJson(json['settings'] ?? {}),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'gender': gender,
      'avatar': avatar,
      'limits': (limits as DailyLimitsModel).toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Child toEntity() => this;
}

class DailyLimitsModel extends DailyLimits {
  const DailyLimitsModel({
    required super.weekdayMinutes,
    required super.weekendMinutes,
  });
  
  factory DailyLimitsModel.fromJson(Map<String, dynamic> json) {
    return DailyLimitsModel(
      weekdayMinutes: json['weekdayMinutes'] ?? 60,
      weekendMinutes: json['weekendMinutes'] ?? 120,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'weekdayMinutes': weekdayMinutes,
      'weekendMinutes': weekendMinutes,
    };
  }
}

class UsageStatsModel extends UsageStats {
  const UsageStatsModel({
    super.minutesUsed,
    super.videosWatched,
    super.gamesPlayed,
    super.storiesRead,
  });
  
  factory UsageStatsModel.fromJson(Map<String, dynamic> json) {
    return UsageStatsModel(
      minutesUsed: json['minutesUsed'] ?? 0,
      videosWatched: json['videosWatched'] ?? 0,
      gamesPlayed: json['gamesPlayed'] ?? 0,
      storiesRead: json['storiesRead'] ?? 0,
    );
  }
}

class ChildSettingsModel extends ChildSettings {
  const ChildSettingsModel({
    super.adsEnabled,
    super.blockedContent,
    super.autoPlay,
    super.maxVideoDuration,
  });
  
  factory ChildSettingsModel.fromJson(Map<String, dynamic> json) {
    return ChildSettingsModel(
      adsEnabled: json['adsEnabled'] ?? false,
      blockedContent: List<String>.from(json['blockedContent'] ?? []),
      autoPlay: json['autoPlay'] ?? false,
      maxVideoDuration: json['maxVideoDuration'] ?? 30,
    );
  }
}
