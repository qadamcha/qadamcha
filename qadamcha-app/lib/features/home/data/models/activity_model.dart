import 'package:equatable/equatable.dart';

class ActivityModel extends Equatable {
  final String id;
  final String childId;
  final String type; // 'app_usage', 'video_watch', 'game_play', 'quest_complete'
  final String? contentId;
  final String? contentTitle;
  final int duration; // minutes
  final DateTime startedAt;
  final DateTime? endedAt;

  const ActivityModel({
    required this.id,
    required this.childId,
    required this.type,
    this.contentId,
    this.contentTitle,
    required this.duration,
    required this.startedAt,
    this.endedAt,
  });
  
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? json['_id'] ?? '',
      childId: json['childId'] ?? '',
      type: json['type'] ?? 'app_usage',
      contentId: json['contentId'],
      contentTitle: json['contentTitle'],
      duration: json['duration'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'duration': duration,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
  
  /// Get activity icon based on type
  String get icon {
    switch (type) {
      case 'video_watch':
        return '📺';
      case 'game_play':
        return '🎮';
      case 'quest_complete':
        return '🏆';
      case 'story_listen':
        return '📖';
      default:
        return '📱';
    }
  }
  
  /// Get activity type label in Uzbek
  String get typeLabel {
    switch (type) {
      case 'video_watch':
        return 'Video ko\'rdi';
      case 'game_play':
        return 'O\'yin o\'ynadi';
      case 'quest_complete':
        return 'Topshiriq bajardi';
      case 'story_listen':
        return 'Ertak eshitdi';
      default:
        return 'Ilova ishlatdi';
    }
  }
  
  /// Format duration as string
  String get durationFormatted {
    if (duration >= 60) {
      final hours = duration ~/ 60;
      final mins = duration % 60;
      return mins > 0 ? '${hours}s ${mins}d' : '${hours} soat';
    }
    return '$duration daqiqa';
  }
  
  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(startedAt);
    
    if (diff.inMinutes < 1) return 'Hozirgina';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays == 1) return 'Kecha';
    return '${diff.inDays} kun oldin';
  }
  
  @override
  List<Object?> get props => [id, childId, type, contentId, duration, startedAt];
}
