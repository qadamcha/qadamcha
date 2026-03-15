import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Subscription?>> getCurrentSubscription();
  Future<Either<Failure, List<Subscription>>> getSubscriptionHistory();
  Future<Either<Failure, List<SubscriptionPlan>>> getAvailablePlans();

  /// Buyurtma yaratish — orderId va amount qaytaradi
  Future<Either<Failure, PaymentOrder>> createOrder({
    required SubscriptionPlan plan,
  });

  /// To'lov holatini tekshirish (polling)
  Future<Either<Failure, OrderStatus>> checkOrder(String orderId);

  Future<Either<Failure, void>> cancelSubscription();

  /// Test rejimida to'g'ridan-to'g'ri obunani faollashtirish (backend orqali)
  Future<Either<Failure, Subscription>> activateTestSubscription({String plan = 'monthly'});

  // ============= Subscribe API Methods =============

  /// Karta tokenini yaratish
  Future<Either<Failure, CardToken>> createCardToken({
    required String cardNumber,
    required String expire,
  });

  /// SMS tasdiqlash kodini so'rash
  Future<Either<Failure, VerifyCodeResult>> getVerifyCode(String token);

  /// Kartani SMS kod bilan tasdiqlash
  Future<Either<Failure, CardToken>> verifyCard({
    required String token,
    required String code,
  });

  /// To'lov qilish (karta tokeni bilan)
  Future<Either<Failure, PaymentResult>> payWithToken({
    required String orderId,
    required String token,
  });
}

class PaymentOrder {
  final String orderId;
  final int amount;

  const PaymentOrder({
    required this.orderId,
    required this.amount,
  });
}

class OrderStatus {
  final String status;
  final bool paid;
  final Subscription? subscription;

  const OrderStatus({
    required this.status,
    required this.paid,
    this.subscription,
  });
}
