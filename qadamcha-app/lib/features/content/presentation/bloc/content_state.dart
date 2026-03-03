part of 'content_bloc.dart';

enum ContentStatus { initial, loading, loaded, error }

class ContentState extends Equatable {
  final ContentStatus status;
  
  /// Serverdan yuklangan BARCHA videolar
  final List<ContentEntity> allContents;
  
  /// Hozir ko'rinayotgan "oyna" (zanjirning ko'rinadigan qismi)
  final List<ContentEntity> windowContents;
  
  /// Oyna boshi indeksi (allContents ichida)
  final int windowStart;
  
  /// Oyna hajmi (default 50)
  final int windowSize;
  
  /// Xatolik xabari
  final String? errorMessage;

  /// Hozirgi filtrlar (qayta yuklash uchun saqlanadi)
  final String? currentType;
  final String? currentCategory;
  final int? currentAge;

  const ContentState({
    this.status = ContentStatus.initial,
    this.allContents = const [],
    this.windowContents = const [],
    this.windowStart = 0,
    this.windowSize = 50,
    this.errorMessage,
    this.currentType,
    this.currentCategory,
    this.currentAge,
  });

  ContentState copyWith({
    ContentStatus? status,
    List<ContentEntity>? allContents,
    List<ContentEntity>? windowContents,
    int? windowStart,
    int? windowSize,
    String? errorMessage,
    String? currentType,
    String? currentCategory,
    int? currentAge,
  }) {
    return ContentState(
      status: status ?? this.status,
      allContents: allContents ?? this.allContents,
      windowContents: windowContents ?? this.windowContents,
      windowStart: windowStart ?? this.windowStart,
      windowSize: windowSize ?? this.windowSize,
      errorMessage: errorMessage ?? this.errorMessage,
      currentType: currentType ?? this.currentType,
      currentCategory: currentCategory ?? this.currentCategory,
      currentAge: currentAge ?? this.currentAge,
    );
  }

  @override
  List<Object?> get props => [
    status, allContents, windowContents, windowStart, windowSize,
    errorMessage, currentType, currentCategory, currentAge,
  ];
}
