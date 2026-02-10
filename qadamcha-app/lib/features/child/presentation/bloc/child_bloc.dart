import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/repositories/child_repository.dart';

part 'child_event.dart';
part 'child_state.dart';

class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final ChildRepository repository;
  
  ChildBloc({required this.repository}) : super(const ChildState()) {
    on<LoadChildrenEvent>(_onLoadChildren);
    on<SelectChildEvent>(_onSelectChild);
    on<AddChildEvent>(_onAddChild);
    on<UpdateChildEvent>(_onUpdateChild);
    on<DeleteChildEvent>(_onDeleteChild);
    on<SetTimeLimitsEvent>(_onSetTimeLimits);
    on<LoadActivityLogsEvent>(_onLoadActivityLogs);
  }
  
  Future<void> _onLoadChildren(
    LoadChildrenEvent event,
    Emitter<ChildState> emit,
  ) async {
    emit(state.copyWith(status: ChildStatus.loading));
    
    final result = await repository.getChildren();
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChildStatus.error,
        errorMessage: failure.message,
      )),
      (children) {
        emit(state.copyWith(
          status: ChildStatus.loaded,
          children: children,
          selectedChild: children.isNotEmpty ? children.first : null,
        ));
      },
    );
  }
  
  void _onSelectChild(
    SelectChildEvent event,
    Emitter<ChildState> emit,
  ) {
    final child = state.children.firstWhere(
      (c) => c.id == event.childId,
      orElse: () => state.children.first,
    );
    emit(state.copyWith(selectedChild: child));
  }
  
  Future<void> _onAddChild(
    AddChildEvent event,
    Emitter<ChildState> emit,
  ) async {
    emit(state.copyWith(status: ChildStatus.loading));
    
    final result = await repository.addChild(
      name: event.name,
      age: event.age,
      gender: event.gender,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChildStatus.error,
        errorMessage: failure.message,
      )),
      (child) {
        final updatedChildren = [...state.children, child];
        emit(state.copyWith(
          status: ChildStatus.loaded,
          children: updatedChildren,
          selectedChild: child,
        ));
      },
    );
  }
  
  Future<void> _onUpdateChild(
    UpdateChildEvent event,
    Emitter<ChildState> emit,
  ) async {
    emit(state.copyWith(status: ChildStatus.loading));
    
    final result = await repository.updateChild(
      childId: event.childId,
      name: event.name,
      age: event.age,
      avatarUrl: event.avatarUrl,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChildStatus.error,
        errorMessage: failure.message,
      )),
      (updatedChild) {
        final updatedChildren = state.children.map((c) {
          return c.id == updatedChild.id ? updatedChild : c;
        }).toList();
        
        emit(state.copyWith(
          status: ChildStatus.loaded,
          children: updatedChildren,
          selectedChild: updatedChild,
        ));
      },
    );
  }
  
  Future<void> _onDeleteChild(
    DeleteChildEvent event,
    Emitter<ChildState> emit,
  ) async {
    emit(state.copyWith(status: ChildStatus.loading));
    
    final result = await repository.deleteChild(event.childId);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChildStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedChildren = state.children
            .where((c) => c.id != event.childId)
            .toList();
        
        emit(state.copyWith(
          status: ChildStatus.loaded,
          children: updatedChildren,
          selectedChild: updatedChildren.isNotEmpty 
              ? updatedChildren.first 
              : null,
        ));
      },
    );
  }
  
  Future<void> _onSetTimeLimits(
    SetTimeLimitsEvent event,
    Emitter<ChildState> emit,
  ) async {
    final result = await repository.setTimeLimits(
      childId: event.childId,
      weekdayMinutes: event.weekdayMinutes,
      weekendMinutes: event.weekendMinutes,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChildStatus.error,
        errorMessage: failure.message,
      )),
      (updatedChild) {
        final updatedChildren = state.children.map((c) {
          return c.id == updatedChild.id ? updatedChild : c;
        }).toList();
        
        emit(state.copyWith(
          children: updatedChildren,
          selectedChild: updatedChild,
        ));
      },
    );
  }
  
  Future<void> _onLoadActivityLogs(
    LoadActivityLogsEvent event,
    Emitter<ChildState> emit,
  ) async {
    final result = await repository.getActivityLogs(childId: event.childId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (logs) => emit(state.copyWith(activityLogs: logs)),
    );
  }
}
