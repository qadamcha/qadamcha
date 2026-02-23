part of 'device_bloc.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDevicesEvent extends DeviceEvent {}

class LinkDeviceEvent extends DeviceEvent {
  final String code;
  final String deviceName;
  final String deviceModel;
  final String uniqueId;
  final DevicePlatform platform;
  
  const LinkDeviceEvent({
    required this.code,
    required this.deviceName,
    required this.deviceModel,
    required this.uniqueId,
    required this.platform,
  });
  
  @override
  List<Object?> get props => [code, deviceName, uniqueId, platform];
}

class RemoveDeviceEvent extends DeviceEvent {
  final String deviceId;
  
  const RemoveDeviceEvent(this.deviceId);
  
  @override
  List<Object?> get props => [deviceId];
}

class BlockDeviceEvent extends DeviceEvent {
  final String deviceId;
  
  const BlockDeviceEvent(this.deviceId);
  
  @override
  List<Object?> get props => [deviceId];
}

class UnblockDeviceEvent extends DeviceEvent {
  final String deviceId;
  
  const UnblockDeviceEvent(this.deviceId);
  
  @override
  List<Object?> get props => [deviceId];
}

/// Joriy qurilma statusini tekshirish (removed/blocked/active)
class CheckDeviceStatusEvent extends DeviceEvent {}
