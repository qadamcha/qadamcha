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
      final response = await apiClient.get('/devices');
      final List<dynamic> data = response.data['devices'] ?? [];
      final devices = data.map((json) => DeviceModel.fromJson(json).toEntity()).toList();
      return Right(devices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmalarni olishda xatolik: $e'));
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
      final response = await apiClient.post('/devices/link', data: {
        'code': code,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'uniqueId': uniqueId,
        'platform': platform.value,
      });
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani ulashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeDevice(String deviceId) async {
    try {
      await apiClient.delete('/devices/$deviceId', data: {});
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani o\'chirishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Device>> blockDevice(String deviceId) async {
    try {
      final response = await apiClient.post('/devices/$deviceId/block', data: {});
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani bloklashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Device>> unblockDevice(String deviceId) async {
    try {
      final response = await apiClient.post('/devices/$deviceId/unblock', data: {});
      final device = DeviceModel.fromJson(response.data['device']).toEntity();
      return Right(device);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilmani blokdan chiqarishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendHeartbeat() async {
    try {
      await apiClient.post('/devices/heartbeat', data: {});
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Heartbeat yuborishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkMyDeviceStatus() async {
    try {
      final response = await apiClient.get('/devices/my-status');
      return Right(Map<String, dynamic>.from(response.data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Qurilma statusini tekshirishda xatolik: $e'));
    }
  }
}
