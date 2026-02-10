part of 'child_bloc.dart';

enum ChildStatus { initial, loading, loaded, error }

class ChildState extends Equatable {
  final ChildStatus status;
  final List<Child> children;
  final Child? selectedChild;
  final List<ActivityLog> activityLogs;
  final String? errorMessage;
  
  const ChildState({
    this.status = ChildStatus.initial,
    this.children = const [],
    this.selectedChild,
    this.activityLogs = const [],
    this.errorMessage,
  });
  
  ChildState copyWith({
    ChildStatus? status,
    List<Child>? children,
    Child? selectedChild,
    List<ActivityLog>? activityLogs,
    String? errorMessage,
  }) {
    return ChildState(
      status: status ?? this.status,
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      activityLogs: activityLogs ?? this.activityLogs,
      errorMessage: errorMessage,
    );
  }
  
  bool get hasChildren => children.isNotEmpty;
  bool get hasSelectedChild => selectedChild != null;
  
  @override
  List<Object?> get props => [status, children, selectedChild, activityLogs, errorMessage];
}
