import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/device_entity.dart';

abstract class DeviceRepository {
  /// Barcha qurilmalarni olish
  Future<Either<Failure, List<Device>>> getDevices();
  
  /// Bola qurilmalarini olish
  Future<Either<Failure, List<Device>>> getChildDevices(String childId);
  
  /// Linking kod yaratish
  Future<Either<Failure, LinkingCode>> generateLinkingCode(String childId);
  
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
  
  /// Qurilmani aktivlashtirish
  Future<Either<Failure, Device>> unblockDevice(String deviceId);
  
  /// Heartbeat yuborish (bola qurilmasidan)
  Future<Either<Failure, void>> sendHeartbeat(String deviceId);
  
  /// Linking kod tekshirish
  Future<Either<Failure, bool>> validateLinkingCode(String code);
}
