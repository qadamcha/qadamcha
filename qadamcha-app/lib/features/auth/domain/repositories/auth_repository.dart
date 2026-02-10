import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// SMS OTP yuborish
  Future<Either<Failure, String>> sendOtp(String phone);
  
  /// OTP ni tekshirish
  Future<Either<Failure, OtpResult>> verifyOtp(String phone, String code);
  
  /// Ro'yxatdan o'tish
  Future<Either<Failure, User>> register({
    required String phone,
    required String name,
    required String pin,
  });
  
  /// Tizimga kirish
  Future<Either<Failure, (User, AuthTokens)>> login({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  });
  
  /// Token yangilash
  Future<Either<Failure, String>> refreshToken();
  
  /// Tizimdan chiqish
  Future<Either<Failure, void>> logout();
  
  /// PIN kodni tiklash
  Future<Either<Failure, String>> resetPin({
    required String phone,
    required String newPin,
  });
  
  /// Foydalanuvchi ma'lumotlarini olish (cache dan)
  Future<Either<Failure, User?>> getCachedUser();
  
  /// Tizimga kirganmi tekshirish
  Future<bool> isLoggedIn();

  /// PIN kodni tekshirish (faqat token borlar uchun)
  Future<Either<Failure, void>> verifyPin(String pin);
}
