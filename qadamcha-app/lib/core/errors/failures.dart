import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  
  const Failure(
    this.message, {
    this.statusCode,
  });
  
  @override
  List<Object?> get props => [message, statusCode];
}

// Server xatolari
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Serverda xatolik yuz berdi', int? statusCode])
      : super(statusCode: statusCode);
}

// Internet aloqasi xatolari
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Internet aloqasi yo\'q']);
}

// Cache xatolari
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Ma\'lumotlar saqlanmagan']);
}

// Autentifikatsiya xatolari
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentifikatsiya xatosi', int? statusCode])
      : super(statusCode: statusCode);
}

// Validatsiya xatolari
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Token muddati tugagan
class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure([super.message = 'Sessiya muddati tugadi']);
}

// Obuna talab qilinadi
class SubscriptionRequiredFailure extends Failure {
  const SubscriptionRequiredFailure([super.message = 'Obuna talab qilinadi']);
}

// Vaqt limiti tugadi
class TimeLimitExceededFailure extends Failure {
  const TimeLimitExceededFailure([super.message = 'Bugungi vaqt limiti tugadi']);
}
