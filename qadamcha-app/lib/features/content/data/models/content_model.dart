import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';

class ContentModel extends ContentEntity {
  const ContentModel({
    required String id,
    required String title,
    required String type,
    required String category,
    required String videoId,
    String? streamUrl,
    String? thumbnailUrl,
    required int duration,
    required int views,
    required int likes,
    required bool isFeatured,
  }) : super(
          id: id,
          title: title,
          type: type,
          category: category,
          videoId: videoId,
          streamUrl: streamUrl,
          thumbnailUrl: thumbnailUrl,
          duration: duration,
          views: views,
          likes: likes,
          isFeatured: isFeatured,
        );

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'video',
      category: json['category'] ?? '',
      videoId: json['videoId'] ?? '',
      streamUrl: json['streamUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'type': type,
      'category': category,
      'videoId': videoId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'views': views,
      'likes': likes,
      'isFeatured': isFeatured,
    };
  }
}
