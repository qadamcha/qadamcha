import '../../domain/entities/device_entity.dart';

class DeviceModel extends Device {
  const DeviceModel({
    required super.id,
    required super.userId,
    super.childId,
    required super.deviceName,
    required super.type,
    required super.platform,
    super.deviceModel,
    required super.uniqueId,
    required super.status,
    super.lastActiveAt,
    required super.linkedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      childId: json['childId'] is Map ? json['childId']['_id'] : json['childId'],
      deviceName: json['deviceName'] ?? 'Noma\'lum qurilma',
      type: DeviceType.fromString(json['mode'] ?? json['type'] ?? 'parent'),
      platform: DevicePlatform.fromString(json['deviceType'] ?? json['platform'] ?? 'android'),
      deviceModel: json['deviceModel'],
      uniqueId: json['deviceId'] ?? json['uniqueId'] ?? '',
      status: DeviceStatus.fromString(json['status'] ?? 'active'),
      lastActiveAt: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : json['lastActiveAt'] != null 
              ? DateTime.parse(json['lastActiveAt'])
              : null,
      linkedAt: DateTime.parse(json['createdAt'] ?? json['linkedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Device toEntity() => this;
}

class LinkingCodeModel extends LinkingCode {
  const LinkingCodeModel({
    required super.code,
    required super.childId,
    required super.expiresAt,
  });

  factory LinkingCodeModel.fromJson(Map<String, dynamic> json) {
    return LinkingCodeModel(
      code: json['code'] ?? '',
      childId: json['childId'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  LinkingCode toEntity() => this;
}
