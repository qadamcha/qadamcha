import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// SMS OTP yuborish
  Future<Either<Failure, String>> sendOtp(String phone, {String? purpose});
  
  /// OTP ni tekshirish
  Future<Either<Failure, OtpResult>> verifyOtp(String phone, String code);
  
  /// Ro'yxatdan o'tish
  Future<Either<Failure, User>> register({
    required String phone,
    required String name,
    required String pin,
    required String verifiedToken,
  });
  
  /// Tizimga kirish
  Future<Either<Failure, (User, AuthTokens, String)>> login({
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
    required String verifiedToken,
  });
  
  /// Foydalanuvchi ma'lumotlarini olish (cache dan)
  Future<Either<Failure, User?>> getCachedUser();
  
  /// Tizimga kirganmi tekshirish
  Future<bool> isLoggedIn();

  /// PIN kodni tekshirish (faqat token borlar uchun)
  Future<Either<Failure, void>> verifyPin(String pin);

  /// PIN kodni o'zgartirish (joriy PIN + yangi PIN)
  Future<Either<Failure, String>> changePin({
    required String currentPin,
    required String newPin,
  });

  /// Profilni yangilash (ismni o'zgartirish)
  Future<Either<Failure, User>> updateProfile({required String name});

  /// Profilni serverdan olish (yangi ma'lumot)
  Future<Either<Failure, User>> getProfile();
}
