import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository repository;
  
  DeviceBloc({required this.repository}) : super(const DeviceState()) {
    on<LoadDevicesEvent>(_onLoadDevices);
    on<LinkDeviceEvent>(_onLinkDevice);
    on<RemoveDeviceEvent>(_onRemoveDevice);
    on<BlockDeviceEvent>(_onBlockDevice);
    on<UnblockDeviceEvent>(_onUnblockDevice);
    on<CheckDeviceStatusEvent>(_onCheckDeviceStatus);
  }
  
  Future<void> _onLoadDevices(
    LoadDevicesEvent event,
    Emitter<DeviceState> emit,
  ) async {
    emit(state.copyWith(status: DeviceLoadStatus.loading));
    
    final result = await repository.getDevices();
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: DeviceLoadStatus.error,
        errorMessage: failure.message,
      )),
      (devices) => emit(state.copyWith(
        status: DeviceLoadStatus.loaded,
        devices: devices,
      )),
    );
  }
  
  Future<void> _onLinkDevice(
    LinkDeviceEvent event,
    Emitter<DeviceState> emit,
  ) async {
    emit(state.copyWith(isLinking: true));
    
    final result = await repository.linkDevice(
      code: event.code,
      deviceName: event.deviceName,
      deviceModel: event.deviceModel,
      uniqueId: event.uniqueId,
      platform: event.platform,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLinking: false,
        linkingStatus: LinkingStatus.failed,
        errorMessage: failure.message,
      )),
      (device) {
        final updatedDevices = [...state.devices, device];
        emit(state.copyWith(
          isLinking: false,
          linkingStatus: LinkingStatus.success,
          devices: updatedDevices,
        ));
      },
    );
  }
  
  Future<void> _onRemoveDevice(
    RemoveDeviceEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.removeDevice(event.deviceId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        final updatedDevices = state.devices
            .where((d) => d.id != event.deviceId)
            .toList();
        emit(state.copyWith(devices: updatedDevices));
      },
    );
  }
  
  Future<void> _onBlockDevice(
    BlockDeviceEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.blockDevice(event.deviceId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updatedDevice) {
        final updatedDevices = state.devices.map((d) {
          return d.id == updatedDevice.id ? updatedDevice : d;
        }).toList();
        emit(state.copyWith(devices: updatedDevices));
      },
    );
  }
  
  Future<void> _onUnblockDevice(
    UnblockDeviceEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.unblockDevice(event.deviceId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updatedDevice) {
        final updatedDevices = state.devices.map((d) {
          return d.id == updatedDevice.id ? updatedDevice : d;
        }).toList();
        emit(state.copyWith(devices: updatedDevices));
      },
    );
  }
  
  /// Joriy qurilma statusini tekshirish
  /// Agar removed → isCurrentDeviceRemoved = true
  /// Agar blocked → isCurrentDeviceBlocked = true
  Future<void> _onCheckDeviceStatus(
    CheckDeviceStatusEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.checkMyDeviceStatus();
    
    result.fold(
      (failure) {
        // Network xatolik — hech narsa qilmaymiz
      },
      (data) {
        final status = data['status'] as String?;
        
        if (status == 'removed') {
          emit(state.copyWith(isCurrentDeviceRemoved: true));
        } else if (status == 'blocked') {
          emit(state.copyWith(
            isCurrentDeviceBlocked: true,
            isCurrentDeviceRemoved: false,
          ));
        } else {
          emit(state.copyWith(
            isCurrentDeviceBlocked: false,
            isCurrentDeviceRemoved: false,
          ));
        }
      },
    );
  }
}
