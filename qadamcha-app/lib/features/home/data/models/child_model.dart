import 'package:equatable/equatable.dart';

class ChildModel extends Equatable {
  final String id;
  final String name;
  final int age;
  final String? gender;
  final String? avatar;
  final int dailyLimit;
  final int weekdayLimit;
  final int weekendLimit;
  final int usedToday;
  final bool isActive;
  final DateTime createdAt;

  const ChildModel({
    required this.id,
    required this.name,
    required this.age,
    this.gender,
    this.avatar,
    this.dailyLimit = 60,
    this.weekdayLimit = 60,
    this.weekendLimit = 120,
    this.usedToday = 0,
    this.isActive = false,
    required this.createdAt,
  });
  
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 6,
      gender: json['gender'],
      avatar: json['avatar'],
      dailyLimit: json['dailyLimit'] ?? 60,
      weekdayLimit: json['weekdayLimit'] ?? 60,
      weekendLimit: json['weekendLimit'] ?? 120,
      usedToday: json['usedToday'] ?? 0,
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'avatar': avatar,
      'dailyLimit': dailyLimit,
      'weekdayLimit': weekdayLimit,
      'weekendLimit': weekendLimit,
      'usedToday': usedToday,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Get remaining time in minutes
  int get remainingMinutes => (dailyLimit - usedToday).clamp(0, dailyLimit);
  
  /// Get usage percentage (0.0 - 1.0)
  double get usagePercentage => dailyLimit > 0 ? usedToday / dailyLimit : 0;
  
  /// Format remaining time as string
  String get remainingTimeFormatted {
    final remaining = remainingMinutes;
    if (remaining >= 60) {
      final hours = remaining ~/ 60;
      final mins = remaining % 60;
      return mins > 0 ? '${hours}s ${mins}d' : '${hours} soat';
    }
    return '$remaining daqiqa';
  }
  
  @override
  List<Object?> get props => [id, name, age, gender, avatar, dailyLimit, usedToday, isActive];
}
