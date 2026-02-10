import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';
import '../models/device_model.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final ApiClient apiClient;

  DeviceRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<Device>>> getDevices() async {
    try {
      final response = await apiClient.dio.get('/devices');
      final List<dynamic> data = response.data['devices'] ?? [];
      final devices = data.map((json) => DeviceModel.fromJson(json).toEntity()).toList();
      return Right(devices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmalarni olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Device>>> getChildDevices(String childId) async {
    try {
      final response = await apiClient.dio.get('/devices/child/$childId');
      final List<dynamic> data = response.data['devices'] ?? [];
      final devices = data.map((json) => DeviceModel.fromJson(json).toEntity()).toList();
      return Right(devices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Bola qurilmalarini olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, LinkingCode>> generateLinkingCode(String childId) async {
    try {
      final response = await apiClient.dio.post('/devices/link-code', data: {
        'childId': childId,
      });
      final code = LinkingCodeModel.fromJson(response.data).toEntity();
      return Right(code);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Linking kod yaratishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Device>> linkDevice({
    required String code,
    required String deviceName,
    required String deviceModel,
    required String uniqueId,
    required DevicePlatform platform,
  }) async {
    try {
      final response = await apiClient.dio.post('/devices/link', data: {
        'code': code,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'uniqueId': uniqueId,
        'platform': platform.value,
      });
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani ulashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeDevice(String deviceId) async {
    try {
      await apiClient.dio.delete('/devices/$deviceId');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani o\'chirishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Device>> blockDevice(String deviceId) async {
    try {
      final response = await apiClient.dio.post('/devices/$deviceId/block');
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani bloklashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Device>> unblockDevice(String deviceId) async {
    try {
      final response = await apiClient.dio.post('/devices/$deviceId/unblock');
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani blokdan chiqarishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendHeartbeat(String deviceId) async {
    try {
      await apiClient.dio.post('/devices/$deviceId/heartbeat');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Heartbeat yuborishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateLinkingCode(String code) async {
    try {
      final response = await apiClient.dio.get('/devices/validate-code/$code');
      final isValid = response.data['valid'] as bool;
      return Right(isValid);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Kodni tekshirishda xatolik: $e'));
    }
  }
}
