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
      userId: json['userId'] ?? '',
      childId: json['childId'],
      deviceName: json['deviceName'] ?? '',
      type: DeviceType.fromString(json['type'] ?? 'parent'),
      platform: DevicePlatform.fromString(json['platform'] ?? 'android'),
      deviceModel: json['deviceModel'],
      uniqueId: json['uniqueId'] ?? '',
      status: DeviceStatus.fromString(json['status'] ?? 'pending'),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt']) 
          : null,
      linkedAt: DateTime.parse(json['linkedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
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
