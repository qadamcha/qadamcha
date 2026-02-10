part of 'content_bloc.dart';

abstract class ContentEvent extends Equatable {
  const ContentEvent();

  @override
  List<Object?> get props => [];
}

class LoadContentEvent extends ContentEvent {
  final bool refresh;
  final String? type;
  final String? category;
  final int? age;

  const LoadContentEvent({
    this.refresh = false,
    this.type,
    this.category,
    this.age,
  });

  @override
  List<Object?> get props => [refresh, type, category, age];
}

class LoadMoreContentEvent extends ContentEvent {}
