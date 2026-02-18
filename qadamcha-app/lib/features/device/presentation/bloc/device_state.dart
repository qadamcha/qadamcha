part of 'device_bloc.dart';

enum DeviceLoadStatus { initial, loading, loaded, error }
enum LinkingStatus { initial, success, failed }

class DeviceState extends Equatable {
  final DeviceLoadStatus status;
  final List<Device> devices;
  final LinkingCode? linkingCode;
  final bool isGeneratingCode;
  final bool isLinking;
  final bool isValidatingCode;
  final bool? isCodeValid;
  final LinkingStatus linkingStatus;
  final String? errorMessage;
  
  const DeviceState({
    this.status = DeviceLoadStatus.initial,
    this.devices = const [],
    this.linkingCode,
    this.isGeneratingCode = false,
    this.isLinking = false,
    this.isValidatingCode = false,
    this.isCodeValid,
    this.linkingStatus = LinkingStatus.initial,
    this.errorMessage,
  });
  
  DeviceState copyWith({
    DeviceLoadStatus? status,
    List<Device>? devices,
    LinkingCode? linkingCode,
    bool? isGeneratingCode,
    bool? isLinking,
    bool? isValidatingCode,
    bool? isCodeValid,
    LinkingStatus? linkingStatus,
    String? errorMessage,
  }) {
    return DeviceState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      linkingCode: linkingCode ?? this.linkingCode,
      isGeneratingCode: isGeneratingCode ?? this.isGeneratingCode,
      isLinking: isLinking ?? this.isLinking,
      isValidatingCode: isValidatingCode ?? this.isValidatingCode,
      isCodeValid: isCodeValid ?? this.isCodeValid,
      linkingStatus: linkingStatus ?? this.linkingStatus,
      errorMessage: errorMessage,
    );
  }
  
  List<Device> get parentDevices => 
      devices.where((d) => d.isParentDevice).toList();
  
  List<Device> get childDevices => 
      devices.where((d) => d.isChildDevice).toList();
  
  List<Device> get onlineDevices => 
      devices.where((d) => d.isOnline).toList();
  
  /// Backend MAX_DEVICES bilan moslashtirish
  int get maxDevices => 3;
  
  @override
  List<Object?> get props => [
    status, 
    devices, 
    linkingCode, 
    isGeneratingCode, 
    isLinking,
    isValidatingCode,
    isCodeValid,
    linkingStatus, 
    errorMessage
  ];
}
