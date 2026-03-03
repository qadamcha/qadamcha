import 'package:equatable/equatable.dart';

class ContentEntity extends Equatable {
  final String id;
  final String title;
  final String type; // 'cartoon', 'game', etc.
  final String category;
  final String series; // multfilm seriyasi (masalan: "Masha va Ayiq")
  final String videoId; // bunny.net video id
  final String? streamUrl;
  final String? thumbnailUrl;
  final int duration;
  final int views;
  final int likes;
  final bool isFeatured;
  final String language; // 'uz', 'ru', 'en'
  final int ageMin;
  final int ageMax;

  const ContentEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.series = '',
    required this.videoId,
    this.streamUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.views,
    required this.likes,
    required this.isFeatured,
    this.language = 'uz',
    this.ageMin = 3,
    this.ageMax = 12,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        category,
        series,
        videoId,
        streamUrl,
        thumbnailUrl,
        duration,
        views,
        likes,
        isFeatured,
        language,
        ageMin,
        ageMax,
      ];
}
