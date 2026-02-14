import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Subscription?>> getCurrentSubscription();
  Future<Either<Failure, List<Subscription>>> getSubscriptionHistory();
  Future<Either<Failure, List<SubscriptionPlan>>> getAvailablePlans();

  /// Buyurtma yaratish — checkout URL qaytaradi
  Future<Either<Failure, PaymentOrder>> createOrder({
    required SubscriptionPlan plan,
  });

  /// To'lov holatini tekshirish (polling)
  Future<Either<Failure, OrderStatus>> checkOrder(String orderId);

  Future<Either<Failure, void>> cancelSubscription();
}

class PaymentOrder {
  final String orderId;
  final String checkoutUrl;
  final int amount;

  const PaymentOrder({
    required this.orderId,
    required this.checkoutUrl,
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
