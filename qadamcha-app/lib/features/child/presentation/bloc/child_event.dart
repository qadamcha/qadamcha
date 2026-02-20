part of 'child_bloc.dart';

abstract class ChildEvent extends Equatable {
  const ChildEvent();

  @override
  List<Object?> get props => [];
}

/// Bolalarni yuklash
class LoadChildrenEvent extends ChildEvent {
  const LoadChildrenEvent();
}

/// Bolani tanlash
class SelectChildEvent extends ChildEvent {
  final String childId;
  
  const SelectChildEvent(this.childId);
  
  @override
  List<Object?> get props => [childId];
}

/// Bola qo'shish
class AddChildEvent extends ChildEvent {
  final String name;
  final int age;
  final String gender;
  
  const AddChildEvent({
    required this.name,
    required this.age,
    required this.gender,
  });
  
  @override
  List<Object?> get props => [name, age, gender];
}

/// Bola ma'lumotlarini yangilash
class UpdateChildEvent extends ChildEvent {
  final String childId;
  final String? name;
  final int? age;
  final String? avatarUrl;
  
  const UpdateChildEvent({
    required this.childId,
    this.name,
    this.age,
    this.avatarUrl,
  });
  
  @override
  List<Object?> get props => [childId, name, age, avatarUrl];
}

/// Bolani o'chirish
class DeleteChildEvent extends ChildEvent {
  final String childId;
  
  const DeleteChildEvent(this.childId);
  
  @override
  List<Object?> get props => [childId];
}

/// Vaqt limitlarini o'rnatish
class SetTimeLimitsEvent extends ChildEvent {
  final String childId;
  final int weekdayMinutes;
  final int weekendMinutes;
  
  const SetTimeLimitsEvent({
    required this.childId,
    required this.weekdayMinutes,
    required this.weekendMinutes,
  });
  
  @override
  List<Object?> get props => [childId, weekdayMinutes, weekendMinutes];
}

/// Faoliyat loglarini yuklash
class LoadActivityLogsEvent extends ChildEvent {
  final String childId;
  
  const LoadActivityLogsEvent(this.childId);
  
  @override
  List<Object?> get props => [childId];
}

/// Haftalik statistikani yuklash
class LoadWeeklyStatsEvent extends ChildEvent {
  final String childId;
  
  const LoadWeeklyStatsEvent(this.childId);
  
  @override
  List<Object?> get props => [childId];
}

/// Faoliyatni backendga yozish (vaqt tracking)
class RecordActivityEvent extends ChildEvent {
  final String childId;
  final String contentId;
  final String activityType;
  final int durationMinutes;
  final String? contentTitle;
  
  const RecordActivityEvent({
    required this.childId,
    required this.contentId,
    required this.activityType,
    required this.durationMinutes,
    this.contentTitle,
  });
  
  @override
  List<Object?> get props => [childId, contentId, activityType, durationMinutes, contentTitle];
}

/// Batch usage sync (LocalMonitoringService → DB)
class SyncUsageEvent extends ChildEvent {
  final String childId;
  final int minutesUsed;
  final int videosWatched;
  final int gamesPlayed;
  final int storiesRead;
  
  const SyncUsageEvent({
    required this.childId,
    required this.minutesUsed,
    required this.videosWatched,
    required this.gamesPlayed,
    required this.storiesRead,
  });
  
  @override
  List<Object?> get props => [childId, minutesUsed, videosWatched, gamesPlayed, storiesRead];
}
