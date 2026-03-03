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
    on<SlideWindowEvent>(_onSlideWindow);
    on<LoadSeriesContentEvent>(_onLoadSeriesContent);
  }

  /// Zanjirning ko'rinadigan oynasini hisoblash
  List<ContentEntity> _getWindow(List<ContentEntity> all, int start, int size) {
    if (all.isEmpty) return [];
    final actualSize = size.clamp(0, all.length);
    final result = <ContentEntity>[];
    for (int i = 0; i < actualSize; i++) {
      result.add(all[(start + i) % all.length]);
    }
    return result;
  }

  /// Barcha videolarni serverdan yuklash
  Future<void> _onLoadContent(
    LoadContentEvent event,
    Emitter<ContentState> emit,
  ) async {
    if (state.status == ContentStatus.loading && !event.refresh) return;

    emit(state.copyWith(
      status: ContentStatus.loading,
      windowStart: 0,
      allContents: event.refresh ? [] : state.allContents,
      windowContents: event.refresh ? [] : state.windowContents,
      currentType: event.type,
      currentCategory: event.category,
      currentAge: event.age,
    ));

    // Barcha videolarni bir paytda yuklash (limit: 500)
    final result = await repository.getContents(
      type: event.type,
      category: event.category,
      age: event.age,
      page: 1,
      limit: 500,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ContentStatus.error,
        errorMessage: failure.message,
      )),
      (contents) {
        final window = _getWindow(contents, 0, state.windowSize);
        emit(state.copyWith(
          status: ContentStatus.loaded,
          allContents: contents,
          windowContents: window,
          windowStart: 0,
        ));
      },
    );
  }

  /// Oynani oldinga siljitish (zanjir bo'ylab)
  void _onSlideWindow(
    SlideWindowEvent event,
    Emitter<ContentState> emit,
  ) {
    if (state.allContents.isEmpty) return;
    
    final total = state.allContents.length;
    // Agar jami videolar oyna hajmidan kam bo'lsa, siljitish kerak emas
    if (total <= state.windowSize) return;

    final newStart = (state.windowStart + event.slideAmount) % total;
    final window = _getWindow(state.allContents, newStart, state.windowSize);

    emit(state.copyWith(
      windowStart: newStart,
      windowContents: window,
    ));
  }

  /// Ma'lum bir series videolarini yuklash (Video Library uchun)
  Future<void> _onLoadSeriesContent(
    LoadSeriesContentEvent event,
    Emitter<ContentState> emit,
  ) async {
    // allContents dan series bo'yicha filtrlash (server chaqirmasdan)
    // Agar allContents bo'sh bo'lsa, avval serverdan yuklash kerak
    if (state.allContents.isEmpty) {
      emit(state.copyWith(status: ContentStatus.loading));
      
      final result = await repository.getContents(
        page: 1,
        limit: 500,
      );

      result.fold(
        (failure) => emit(state.copyWith(
          status: ContentStatus.error,
          errorMessage: failure.message,
        )),
        (contents) {
          final seriesVideos = contents
              .where((c) => c.series == event.series || 
                     (event.series == 'Boshqalar' && c.series.isEmpty))
              .toList();
          final window = _getWindow(seriesVideos, 0, state.windowSize);
          emit(state.copyWith(
            status: ContentStatus.loaded,
            allContents: contents,
            windowContents: window,
            windowStart: 0,
          ));
        },
      );
    } else {
      // allContents mavjud — faqat filtrlash
      final seriesVideos = state.allContents
          .where((c) => c.series == event.series || 
                 (event.series == 'Boshqalar' && c.series.isEmpty))
          .toList();
      final window = _getWindow(seriesVideos, 0, state.windowSize);
      emit(state.copyWith(
        status: ContentStatus.loaded,
        windowContents: window,
        windowStart: 0,
      ));
    }
  }
}
