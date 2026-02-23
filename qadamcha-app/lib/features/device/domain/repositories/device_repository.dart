import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/device_entity.dart';

abstract class DeviceRepository {
  /// Barcha qurilmalarni olish
  Future<Either<Failure, List<Device>>> getDevices();
  
  /// Qurilmani ulash (bola qurilmasi)
  Future<Either<Failure, Device>> linkDevice({
    required String code,
    required String deviceName,
    required String deviceModel,
    required String uniqueId,
    required DevicePlatform platform,
  });
  
  /// Qurilmani o'chirish
  Future<Either<Failure, void>> removeDevice(String deviceId);
  
  /// Qurilmani bloklash
  Future<Either<Failure, Device>> blockDevice(String deviceId);
  
  /// Qurilmani blokdan chiqarish
  Future<Either<Failure, Device>> unblockDevice(String deviceId);
  
  /// Heartbeat yuborish
  Future<Either<Failure, void>> sendHeartbeat();
  
  /// Joriy qurilma statusini tekshirish
  Future<Either<Failure, Map<String, dynamic>>> checkMyDeviceStatus();
}
