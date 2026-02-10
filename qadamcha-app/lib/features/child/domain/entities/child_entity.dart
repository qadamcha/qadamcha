import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String gender;
  final String? avatar;
  final DailyLimits limits;
  final UsageStats todayUsage;
  final ChildSettings settings;
  final DateTime createdAt;
  
  const Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.gender,
    this.avatar,
    required this.limits,
    required this.todayUsage,
    required this.settings,
    required this.createdAt,
  });
  
  String get ageGroup {
    if (age <= 5) return '3-5';
    if (age <= 8) return '6-8';
    if (age <= 12) return '9-12';
    return '13+';
  }
  
  int get remainingMinutes {
    final today = DateTime.now().weekday;
    final limit = (today >= 6) ? limits.weekendMinutes : limits.weekdayMinutes;
    return (limit - todayUsage.minutesUsed).clamp(0, limit);
  }
  
  bool get hasTimeRemaining => remainingMinutes > 0;
  
  @override
  List<Object?> get props => [id, name, age, gender, limits, todayUsage];
}

class DailyLimits extends Equatable {
  final int weekdayMinutes;
  final int weekendMinutes;
  
  const DailyLimits({
    required this.weekdayMinutes,
    required this.weekendMinutes,
  });
  
  factory DailyLimits.defaultLimits() {
    return const DailyLimits(weekdayMinutes: 60, weekendMinutes: 120);
  }
  
  @override
  List<Object?> get props => [weekdayMinutes, weekendMinutes];
}

class UsageStats extends Equatable {
  final int minutesUsed;
  final int videosWatched;
  final int gamesPlayed;
  final int storiesRead;
  
  const UsageStats({
    this.minutesUsed = 0,
    this.videosWatched = 0,
    this.gamesPlayed = 0,
    this.storiesRead = 0,
  });
  
  @override
  List<Object?> get props => [minutesUsed, videosWatched, gamesPlayed, storiesRead];
}

class ChildSettings extends Equatable {
  final bool adsEnabled;
  final List<String> blockedContent;
  final bool autoPlay;
  final int maxVideoDuration;
  
  const ChildSettings({
    this.adsEnabled = false,
    this.blockedContent = const [],
    this.autoPlay = false,
    this.maxVideoDuration = 30,
  });
  
  @override
  List<Object?> get props => [adsEnabled, blockedContent, autoPlay, maxVideoDuration];
}
