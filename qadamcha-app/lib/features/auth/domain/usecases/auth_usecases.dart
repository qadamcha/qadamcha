import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;
  
  SendOtpUseCase(this.repository);
  
  Future<Either<Failure, String>> call(String phone, {String? purpose}) {
    return repository.sendOtp(phone, purpose: purpose);
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;
  
  VerifyOtpUseCase(this.repository);
  
  Future<Either<Failure, OtpResult>> call(String phone, String code) {
    return repository.verifyOtp(phone, code);
  }
}

class RegisterUseCase {
  final AuthRepository repository;
  
  RegisterUseCase(this.repository);
  
  Future<Either<Failure, User>> call({
    required String phone,
    required String name,
    required String pin,
  }) {
    return repository.register(phone: phone, name: name, pin: pin);
  }
}

class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<Either<Failure, (User, AuthTokens)>> call({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  }) {
    return repository.login(
      phone: phone,
      pin: pin,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
    );
  }
}

class LogoutUseCase {
  final AuthRepository repository;
  
  LogoutUseCase(this.repository);
  
  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}

class CheckAuthUseCase {
  final AuthRepository repository;
  
  CheckAuthUseCase(this.repository);
  
  Future<bool> call() {
    return repository.isLoggedIn();
  }
}

class GetCachedUserUseCase {
  final AuthRepository repository;
  
  GetCachedUserUseCase(this.repository);
  
  Future<Either<Failure, User?>> call() {
    return repository.getCachedUser();
  }
}
