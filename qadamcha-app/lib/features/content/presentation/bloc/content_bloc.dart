import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';
import 'package:qadamcha_app/features/content/domain/repositories/content_repository.dart';

part 'content_event.dart';
part 'content_state.dart';

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final ContentRepository repository;

  ContentBloc({required this.repository}) : super(const ContentState()) {
    on<LoadContentEvent>(_onLoadContent);
    on<LoadMoreContentEvent>(_onLoadMoreContent);
  }

  Future<void> _onLoadContent(
    LoadContentEvent event,
    Emitter<ContentState> emit,
  ) async {
    if (state.status == ContentStatus.loading && !event.refresh) return;

    emit(state.copyWith(
      status: ContentStatus.loading,
      page: 1, // Reset page on fresh load
      contents: event.refresh ? [] : state.contents,
      hasReachedMax: false,
    ));

    final result = await repository.getContents(
      type: event.type,
      category: event.category,
      age: event.age,
      page: 1,
      limit: 20,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ContentStatus.error,
        errorMessage: failure.message,
      )),
      (contents) => emit(state.copyWith(
        status: ContentStatus.loaded,
        contents: contents,
        hasReachedMax: contents.length < 20,
        page: 1,
      )),
    );
  }

  Future<void> _onLoadMoreContent(
    LoadMoreContentEvent event,
    Emitter<ContentState> emit,
  ) async {
    if (state.hasReachedMax || state.status == ContentStatus.loading) return;

    final nextPage = state.page + 1;
    
    // Note: We might want to pass current filters here. For now assuming basic pagination.
    // Ideally state should store current filters.
    
    final result = await repository.getContents(
      page: nextPage,
      limit: 20,
    );

     result.fold(
      (failure) => emit(state.copyWith(
        status: ContentStatus.error,
        errorMessage: failure.message,
      )),
      (newContents) {
        if (newContents.isEmpty) {
          emit(state.copyWith(hasReachedMax: true));
        } else {
          emit(state.copyWith(
            status: ContentStatus.loaded,
            contents: List.of(state.contents)..addAll(newContents),
            hasReachedMax: newContents.length < 20,
            page: nextPage,
          ));
        }
      },
    );
  }
}
