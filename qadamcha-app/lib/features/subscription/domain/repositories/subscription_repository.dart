import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  /// Joriy obunani olish
  Future<Either<Failure, Subscription?>> getCurrentSubscription();
  
  /// Obuna tarixini olish
  Future<Either<Failure, List<Subscription>>> getSubscriptionHistory();
  
  /// Obuna rejalarini olish
  Future<Either<Failure, List<SubscriptionPlan>>> getAvailablePlans();
  
  /// Yangi obunaga yozilish
  Future<Either<Failure, Subscription>> createSubscription({
    required SubscriptionPlan plan,
    required String paymentMethod,
  });
  
  /// To'lov jarayonini boshlash
  Future<Either<Failure, PaymentIntent>> initiatePayment({
    required SubscriptionPlan plan,
    required String paymentMethod, // 'payme', 'click', 'uzum'
  });
  
  /// To'lovni tasdiqlash
  Future<Either<Failure, Subscription>> confirmPayment({
    required String transactionId,
    required String paymentMethod,
  });
  
  /// Obunani bekor qilish
  Future<Either<Failure, Subscription>> cancelSubscription(String subscriptionId);
  
  /// Avtomatik yangilashni o'chirish/yoqish
  Future<Either<Failure, Subscription>> toggleAutoRenew(String subscriptionId);
}

class PaymentIntent {
  final String id;
  final String paymentUrl;
  final String transactionId;
  final int amount;
  final String currency;
  final DateTime expiresAt;
  
  const PaymentIntent({
    required this.id,
    required this.paymentUrl,
    required this.transactionId,
    required this.amount,
    this.currency = 'UZS',
    required this.expiresAt,
  });
}
