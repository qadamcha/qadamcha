import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/repositories/child_repository.dart';
import '../models/child_models.dart';

class ChildRepositoryImpl implements ChildRepository {
  final ApiClient apiClient;

  ChildRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<Child>>> getChildren() async {
    try {
      final response = await apiClient.dio.get('/children');
      final List<dynamic> data = response.data['children'] ?? [];
      final children = data.map((json) => ChildModel.fromJson(json).toEntity()).toList();
      return Right(children);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bolalar ro\'yxatini olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Child>> getChild(String childId) async {
    try {
      final response = await apiClient.dio.get('/children/$childId');
      final child = ChildModel.fromJson(response.data['child']).toEntity();
      return Right(child);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bolani olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Child>> addChild({
    required String name,
    required int age,
    required String gender,
  }) async {
    try {
      final response = await apiClient.dio.post('/children', data: {
        'name': name,
        'age': age,
        'gender': gender,
      });
      final child = ChildModel.fromJson(response.data['child']).toEntity();
      return Right(child);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bola qo\'shishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Child>> updateChild({
    required String childId,
    String? name,
    int? age,
    String? avatarUrl,
  }) async {
    try {
      final response = await apiClient.dio.patch('/children/$childId', data: {
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
      final child = ChildModel.fromJson(response.data['child']).toEntity();
      return Right(child);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bolani yangilashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChild(String childId) async {
    try {
      await apiClient.dio.delete('/children/$childId');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bolani o\'chirishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Child>> setTimeLimits({
    required String childId,
    required int weekdayMinutes,
    required int weekendMinutes,
  }) async {
    try {
      final response = await apiClient.dio.patch('/children/$childId/limits', data: {
        'weekdayMinutes': weekdayMinutes,
        'weekendMinutes': weekendMinutes,
      });
      final child = ChildModel.fromJson(response.data['child']).toEntity();
      return Right(child);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Vaqt limitini o\'rnatishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Child>> updateSettings({
    required String childId,
    bool? allowGames,
    bool? allowVideos,
    bool? allowStories,
    bool? safeMode,
  }) async {
    try {
      final response = await apiClient.dio.patch('/children/$childId/settings', data: {
        if (allowGames != null) 'allowGames': allowGames,
        if (allowVideos != null) 'allowVideos': allowVideos,
        if (allowStories != null) 'allowStories': allowStories,
        if (safeMode != null) 'safeMode': safeMode,
      });
      final child = ChildModel.fromJson(response.data['child']).toEntity();
      return Right(child);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Sozlamalarni yangilashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLog>>> getActivityLogs({
    required String childId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      
      final response = await apiClient.dio.get(
        '/children/$childId/activity',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['activities'] ?? [];
      final logs = data.map((json) => ActivityLogModel.fromJson(json).toEntity()).toList();
      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Faoliyat tarixini olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, WeeklyStats>> getWeeklyStats(String childId) async {
    try {
      final response = await apiClient.dio.get('/children/$childId/stats/weekly');
      final stats = WeeklyStatsModel.fromJson(response.data['stats']).toEntity();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Haftalik statistikani olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> recordActivity({
    required String childId,
    required String contentId,
    required String activityType,
    required int durationMinutes,
  }) async {
    try {
      await apiClient.dio.post('/children/$childId/activity', data: {
        'contentId': contentId,
        'activityType': activityType,
        'durationMinutes': durationMinutes,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Faoliyatni yozishda xatolik: $e'));
    }
  }
}

// Models for API responses
class ActivityLogModel {
  final String id;
  final String childId;
  final String contentId;
  final String contentTitle;
  final String activityType;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;

  ActivityLogModel({
    required this.id,
    required this.childId,
    required this.contentId,
    required this.contentTitle,
    required this.activityType,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      childId: json['childId'] ?? '',
      contentId: json['contentId'] ?? '',
      contentTitle: json['contentTitle'] ?? '',
      activityType: json['activityType'] ?? 'video',
      durationMinutes: json['durationMinutes'] ?? 0,
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    );
  }

  ActivityLog toEntity() {
    return ActivityLog(
      id: id,
      childId: childId,
      contentId: contentId,
      contentTitle: contentTitle,
      activityType: activityType,
      durationMinutes: durationMinutes,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }
}

class WeeklyStatsModel {
  final int totalMinutes;
  final int videosWatched;
  final int gamesPlayed;
  final int storiesRead;
  final List<int> dailyMinutes;

  WeeklyStatsModel({
    required this.totalMinutes,
    required this.videosWatched,
    required this.gamesPlayed,
    required this.storiesRead,
    required this.dailyMinutes,
  });

  factory WeeklyStatsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyStatsModel(
      totalMinutes: json['totalMinutes'] ?? 0,
      videosWatched: json['videosWatched'] ?? 0,
      gamesPlayed: json['gamesPlayed'] ?? 0,
      storiesRead: json['storiesRead'] ?? 0,
      dailyMinutes: List<int>.from(json['dailyMinutes'] ?? [0, 0, 0, 0, 0, 0, 0]),
    );
  }

  WeeklyStats toEntity() {
    return WeeklyStats(
      totalMinutes: totalMinutes,
      videosWatched: videosWatched,
      gamesPlayed: gamesPlayed,
      storiesRead: storiesRead,
      dailyMinutes: dailyMinutes,
    );
  }
}
