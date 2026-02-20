import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/child_entity.dart';

/// Bola foydalanish kontentlari turi
enum ActivityType { video, game, story, song }

abstract class ChildRepository {
  /// Barcha bolalarni olish
  Future<Either<Failure, List<Child>>> getChildren();
  
  /// Bitta bolani olish
  Future<Either<Failure, Child>> getChild(String childId);
  
  /// Bola qo'shish
  Future<Either<Failure, Child>> addChild({
    required String name,
    required int age,
    required String gender,
  });
  
  /// Bola ma'lumotlarini yangilash
  Future<Either<Failure, Child>> updateChild({
    required String childId,
    String? name,
    int? age,
    String? avatarUrl,
  });
  
  /// Bolani o'chirish
  Future<Either<Failure, void>> deleteChild(String childId);
  
  /// Vaqt limitlarini o'rnatish
  Future<Either<Failure, Child>> setTimeLimits({
    required String childId,
    required int weekdayMinutes,
    required int weekendMinutes,
  });
  
  /// Sozlamalarni yangilash
  Future<Either<Failure, Child>> updateSettings({
    required String childId,
    bool? allowGames,
    bool? allowVideos,
    bool? allowStories,
    bool? safeMode,
  });
  
  /// Bugungi faoliyat loglarini olish
  Future<Either<Failure, List<ActivityLog>>> getActivityLogs({
    required String childId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Haftalik statistikani olish
  Future<Either<Failure, WeeklyStats>> getWeeklyStats(String childId);
  
  /// Faoliyatni yozish
  Future<Either<Failure, void>> recordActivity({
    required String childId,
    required String contentId,
    required String activityType,
    required int durationMinutes,
    String? contentTitle,
  });

  /// Batch usage sync (LocalMonitoringService → DB)
  Future<Either<Failure, void>> syncUsage({
    required String childId,
    required int minutesUsed,
    required int videosWatched,
    required int gamesPlayed,
    required int storiesRead,
  });
}

class ActivityLog extends Equatable {
  final String id;
  final String childId;
  final String contentId;
  final String contentTitle;
  final String activityType;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  
  const ActivityLog({
    required this.id,
    required this.childId,
    required this.contentId,
    required this.contentTitle,
    required this.activityType,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
  });
  
  @override
  List<Object?> get props => [id, contentId, durationMinutes, startedAt];
}

class WeeklyStats extends Equatable {
  final int totalMinutes;
  final int videosWatched;
  final int gamesPlayed;
  final int storiesRead;
  final List<int> dailyMinutes; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  
  const WeeklyStats({
    required this.totalMinutes,
    required this.videosWatched,
    required this.gamesPlayed,
    required this.storiesRead,
    required this.dailyMinutes,
  });
  
  @override
  List<Object?> get props => [totalMinutes, dailyMinutes];
}
