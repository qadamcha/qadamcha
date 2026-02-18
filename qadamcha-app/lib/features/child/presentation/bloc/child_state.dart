part of 'child_bloc.dart';

enum ChildStatus { initial, loading, loaded, error }

class ChildState extends Equatable {
  final ChildStatus status;
  final List<Child> children;
  final Child? selectedChild;
  final List<ActivityLog> activityLogs;
  final WeeklyStats? weeklyStats;
  final String? errorMessage;
  
  const ChildState({
    this.status = ChildStatus.initial,
    this.children = const [],
    this.selectedChild,
    this.activityLogs = const [],
    this.weeklyStats,
    this.errorMessage,
  });
  
  ChildState copyWith({
    ChildStatus? status,
    List<Child>? children,
    Child? selectedChild,
    bool clearSelectedChild = false,
    List<ActivityLog>? activityLogs,
    WeeklyStats? weeklyStats,
    String? errorMessage,
  }) {
    return ChildState(
      status: status ?? this.status,
      children: children ?? this.children,
      selectedChild: clearSelectedChild ? null : (selectedChild ?? this.selectedChild),
      activityLogs: activityLogs ?? this.activityLogs,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      errorMessage: errorMessage,
    );
  }
  
  bool get hasChildren => children.isNotEmpty;
  bool get hasSelectedChild => selectedChild != null;
  
  @override
  List<Object?> get props => [status, children, selectedChild, activityLogs, weeklyStats, errorMessage];
}
