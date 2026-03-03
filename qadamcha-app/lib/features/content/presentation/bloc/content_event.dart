part of 'content_bloc.dart';

abstract class ContentEvent extends Equatable {
  const ContentEvent();

  @override
  List<Object?> get props => [];
}

/// Barcha videolarni serverdan yuklash (birinchi marta yoki pull-to-refresh)
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

/// Oynani oldinga siljitish (scroll oxiriga yetganda)
/// windowStart += slideAmount, 10 ta qo'shiladi, 10 ta olinadi
class SlideWindowEvent extends ContentEvent {
  final int slideAmount;
  const SlideWindowEvent({this.slideAmount = 10});

  @override
  List<Object?> get props => [slideAmount];
}

/// Ma'lum bir series videolarini oyna ichidan olish
class LoadSeriesContentEvent extends ContentEvent {
  final String series;
  const LoadSeriesContentEvent({required this.series});

  @override
  List<Object?> get props => [series];
}
