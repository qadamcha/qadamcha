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
  Future<Either<Failure, String>> sendOtp(String phone) async {
    try {
      final message = await remoteDataSource.sendOtp(phone);
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
  }) async {
    try {
      final user = await remoteDataSource.register(phone, name, pin);
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
  Future<Either<Failure, (User, AuthTokens)>> login({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  }) async {
    try {
      final (user, tokens) = await remoteDataSource.login(
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
      
      return Right((user.toEntity(), tokens));
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

      final newTokens = await remoteDataSource.refreshToken(tokens.refreshToken);
      await localDataSource.cacheTokens(newTokens);

      return Right(newTokens.accessToken);
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
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      // Logout locally even if server fails
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
  }) async {
    try {
      final message = await remoteDataSource.resetPin(phone, newPin);
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
      await remoteDataSource.verifyPin(pin);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
