import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, String>> sendOtp(String phone, {String? purpose}) async {
    try {
      final message = await remoteDataSource.sendOtp(phone, purpose: purpose);
      return Right(message);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, OtpResult>> verifyOtp(String phone, String code) async {
    try {
      final result = await remoteDataSource.verifyOtp(phone, code);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, User>> register({
    required String phone,
    required String name,
    required String pin,
    required String verifiedToken,
  }) async {
    try {
      final user = await remoteDataSource.register(phone, name, pin, verifiedToken: verifiedToken);

      // Ro'yxatdan keyin avtomatik login — tokenlarni olish
      try {
        final (loggedUser, tokens, _) = await remoteDataSource.login(
          phone: phone,
          pin: pin,
          deviceId: 'default',
        );
        await localDataSource.cacheTokens(tokens);
        await localDataSource.cacheUser(loggedUser);
        await localDataSource.setLoggedIn(true);
        // PIN hash'ni lokal saqlash (keyingi kirish tez bo'lishi uchun)
        await localDataSource.cachePinHash(pin);
      } catch (_) {
        // Login xato bo'lsa ham ro'yxatdan o'tish muvaffaqiyatli
      }

      return Right(user.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, (User, AuthTokens, String)>> login({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  }) async {
    try {
      final (user, tokens, deviceMode) = await remoteDataSource.login(
        phone: phone,
        pin: pin,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );
      
      // Cache tokens and user
      await localDataSource.cacheTokens(tokens);
      await localDataSource.cacheUser(user);
      await localDataSource.setLoggedIn(true);
      // PIN hash'ni lokal saqlash (keyingi kirish tez bo'lishi uchun)
      await localDataSource.cachePinHash(pin);
      // Device mode ni saqlash
      await localDataSource.cacheDeviceMode(deviceMode);
      
      return Right((user.toEntity(), tokens, deviceMode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final tokens = await localDataSource.getCachedTokens();
      if (tokens == null) {
        return const Left(TokenExpiredFailure());
      }
      
      final newToken = await remoteDataSource.refreshToken(tokens.refreshToken);
      await localDataSource.cacheTokens(AuthTokensModel(
        accessToken: newToken,
        refreshToken: tokens.refreshToken,
      ));
      
      return Right(newToken);
    } on UnauthorizedException {
      await localDataSource.clearCache();
      return const Left(TokenExpiredFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearPinHash();
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      // Logout locally even if server fails
      await localDataSource.clearPinHash();
      await localDataSource.clearCache();
      return const Right(null);
    }
  }
  
  @override
  Future<Either<Failure, User?>> getCachedUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user?.toEntity());
    } catch (e) {
      return const Left(CacheFailure());
    }
  }
  
  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }
  
  @override
  Future<Either<Failure, String>> resetPin({
    required String phone,
    required String newPin,
    required String verifiedToken,
  }) async {
    try {
      final message = await remoteDataSource.resetPin(phone, newPin, verifiedToken: verifiedToken);
      // Yangi PIN hash'ni lokal saqlash
      await localDataSource.cachePinHash(newPin);
      return Right(message);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPin(String pin) async {
    try {
      // Avval lokal tekshirish (1ms — serverga bormasdan)
      final localResult = await localDataSource.verifyPinLocally(pin);
      if (localResult) {
        return const Right(null); // ✅ Lokal tasdiqlandi!
      }
      
      // Lokal hash yo'q (birinchi kirish yoki boshqa qurilma) — serverda tekshirish
      await remoteDataSource.verifyPin(pin);
      // Muvaffaqiyat — keyingi safar uchun lokal saqlash
      await localDataSource.cachePinHash(pin);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final message = await remoteDataSource.changePin(currentPin, newPin);
      // Yangi PIN hash'ni lokal saqlash
      await localDataSource.cachePinHash(newPin);
      return Right(message);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({required String name}) async {
    try {
      final response = await remoteDataSource.updateProfile(name: name);
      // Lokal cache yangilash
      await localDataSource.cacheUser(response);
      return Right(response.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final response = await remoteDataSource.getProfile();
      // Lokal cache yangilash
      await localDataSource.cacheUser(response);
      return Right(response.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
