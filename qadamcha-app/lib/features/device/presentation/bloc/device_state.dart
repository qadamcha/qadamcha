part of 'device_bloc.dart';

enum DeviceLoadStatus { initial, loading, loaded, error }
enum LinkingStatus { initial, success, failed }

class DeviceState extends Equatable {
  final DeviceLoadStatus status;
  final List<Device> devices;
  final bool isLinking;
  final LinkingStatus linkingStatus;
  final String? errorMessage;
  
  /// Joriy qurilma bloklangan yoki yo'q
  final bool isCurrentDeviceBlocked;
  
  /// Joriy qurilma o'chirilgan (removed) yoki yo'q
  final bool isCurrentDeviceRemoved;
  
  /// Backend'dan kelgan maxDevices
  final int maxDevices;
  
  const DeviceState({
    this.status = DeviceLoadStatus.initial,
    this.devices = const [],
    this.isLinking = false,
    this.linkingStatus = LinkingStatus.initial,
    this.errorMessage,
    this.isCurrentDeviceBlocked = false,
    this.isCurrentDeviceRemoved = false,
    this.maxDevices = 3,
  });
  
  DeviceState copyWith({
    DeviceLoadStatus? status,
    List<Device>? devices,
    bool? isLinking,
    LinkingStatus? linkingStatus,
    String? errorMessage,
    bool? isCurrentDeviceBlocked,
    bool? isCurrentDeviceRemoved,
    int? maxDevices,
  }) {
    return DeviceState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      isLinking: isLinking ?? this.isLinking,
      linkingStatus: linkingStatus ?? this.linkingStatus,
      errorMessage: errorMessage,
      isCurrentDeviceBlocked: isCurrentDeviceBlocked ?? this.isCurrentDeviceBlocked,
      isCurrentDeviceRemoved: isCurrentDeviceRemoved ?? this.isCurrentDeviceRemoved,
      maxDevices: maxDevices ?? this.maxDevices,
    );
  }
  
  List<Device> get parentDevices => 
      devices.where((d) => d.isParentDevice).toList();
  
  List<Device> get childDevices => 
      devices.where((d) => d.isChildDevice).toList();
  
  List<Device> get onlineDevices => 
      devices.where((d) => d.isOnline).toList();
  
  @override
  List<Object?> get props => [
    status, 
    devices, 
    isLinking,
    linkingStatus, 
    errorMessage,
    isCurrentDeviceBlocked,
    isCurrentDeviceRemoved,
    maxDevices,
  ];
}
