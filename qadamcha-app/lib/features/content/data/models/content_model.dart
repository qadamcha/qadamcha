import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';

class ContentModel extends ContentEntity {
  const ContentModel({
    required super.id,
    required super.title,
    required super.type,
    required super.category,
    required super.videoId,
    super.streamUrl,
    super.thumbnailUrl,
    required super.duration,
    required super.views,
    required super.likes,
    required super.isFeatured,
    super.language,
    super.ageMin,
    super.ageMax,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    // Bunny.net CDN host
    const cdnHost = 'vz-b4d1a082-e06.b-cdn.net';
    final videoId = json['videoId'] ?? '';

    // thumbnail: backend "thumbnail" yoki "thumbnailUrl" bo'lishi mumkin
    String? thumbUrl = json['thumbnailUrl'] ?? json['thumbnail'];
    if ((thumbUrl == null || thumbUrl.isEmpty) && videoId.isNotEmpty) {
      thumbUrl = 'https://$cdnHost/$videoId/thumbnail.jpg';
    }

    // streamUrl: backend "streamUrl" yoki videoId dan yaratish
    String? stream = json['streamUrl'];
    if ((stream == null || stream.isEmpty) && videoId.isNotEmpty) {
      stream = 'https://$cdnHost/$videoId/playlist.m3u8';
    }

    // ageRange: nested object { min, max }
    final ageRange = json['ageRange'];
    int ageMin = 3;
    int ageMax = 12;
    if (ageRange is Map) {
      ageMin = (ageRange['min'] ?? 3) is int ? ageRange['min'] : int.tryParse('${ageRange['min']}') ?? 3;
      ageMax = (ageRange['max'] ?? 12) is int ? ageRange['max'] : int.tryParse('${ageRange['max']}') ?? 12;
    }

    return ContentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'cartoon',
      category: json['category'] ?? '',
      videoId: videoId,
      streamUrl: stream,
      thumbnailUrl: thumbUrl,
      duration: json['duration'] ?? 0,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      language: json['language'] ?? 'uz',
      ageMin: ageMin,
      ageMax: ageMax,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'type': type,
      'category': category,
      'videoId': videoId,
      'streamUrl': streamUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'views': views,
      'likes': likes,
      'isFeatured': isFeatured,
      'language': language,
      'ageRange': {'min': ageMin, 'max': ageMax},
    };
  }
}
