import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final String id;
  final String userId;
  final String? childId;
  final String deviceName;
  final DeviceType type;
  final DevicePlatform platform;
  final String? deviceModel;
  final String uniqueId;
  final DeviceStatus status;
  final DateTime? lastActiveAt;
  final DateTime linkedAt;
  
  const Device({
    required this.id,
    required this.userId,
    this.childId,
    required this.deviceName,
    required this.type,
    required this.platform,
    this.deviceModel,
    required this.uniqueId,
    required this.status,
    this.lastActiveAt,
    required this.linkedAt,
  });
  
  bool get isOnline {
    if (lastActiveAt == null) return false;
    final diff = DateTime.now().difference(lastActiveAt!);
    return diff.inMinutes < 5;
  }
  
  bool get isChildDevice => type == DeviceType.child;
  bool get isParentDevice => type == DeviceType.parent;
  
  @override
  List<Object?> get props => [id, userId, childId, status, lastActiveAt];
}

enum DeviceType {
  parent('parent', 'Ota-ona'),
  child('child', 'Bola');
  
  final String value;
  final String label;
  
  const DeviceType(this.value, this.label);
  
  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceType.parent,
    );
  }
}

enum DevicePlatform {
  android('android', 'Android', '📱'),
  ios('ios', 'iOS', '🍎'),
  web('web', 'Web', '🌐');
  
  final String value;
  final String label;
  final String emoji;
  
  const DevicePlatform(this.value, this.label, this.emoji);
  
  static DevicePlatform fromString(String value) {
    return DevicePlatform.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DevicePlatform.android,
    );
  }
}

enum DeviceStatus {
  pending('pending', 'Kutilmoqda'),
  active('active', 'Faol'),
  blocked('blocked', 'Bloklangan'),
  removed('removed', 'O\'chirilgan');
  
  final String value;
  final String label;
  
  const DeviceStatus(this.value, this.label);
  
  static DeviceStatus fromString(String value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceStatus.pending,
    );
  }
}

class LinkingCode extends Equatable {
  final String code;
  final String childId;
  final DateTime expiresAt;
  
  const LinkingCode({
    required this.code,
    required this.childId,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
  
  @override
  List<Object?> get props => [code, childId, expiresAt];
}
