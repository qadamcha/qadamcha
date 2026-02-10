part of 'content_bloc.dart';

enum ContentStatus { initial, loading, loaded, error }

class ContentState extends Equatable {
  final ContentStatus status;
  final List<ContentEntity> contents;
  final bool hasReachedMax;
  final String? errorMessage;
  final int page;

  const ContentState({
    this.status = ContentStatus.initial,
    this.contents = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.page = 1,
  });

  ContentState copyWith({
    ContentStatus? status,
    List<ContentEntity>? contents,
    bool? hasReachedMax,
    String? errorMessage,
    int? page,
  }) {
    return ContentState(
      status: status ?? this.status,
      contents: contents ?? this.contents,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [status, contents, hasReachedMax, errorMessage, page];
}
