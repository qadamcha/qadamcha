import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, Subscription?>> getCurrentSubscription() async {
    try {
      final response = await apiClient.dio.get('/subscription/current');
      if (response.data['subscription'] == null) {
        return const Right(null);
      }
      final subscription = SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Subscription>>> getSubscriptionHistory() async {
    try {
      final response = await apiClient.dio.get('/subscription/history');
      final List<dynamic> data = response.data['subscriptions'] ?? [];
      final subscriptions = data.map((json) => SubscriptionModel.fromJson(json).toEntity()).toList();
      return Right(subscriptions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obuna tarixini olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getAvailablePlans() async {
    // Plans are static, no need for API call
    return Right(SubscriptionPlan.values.toList());
  }

  @override
  Future<Either<Failure, Subscription>> createSubscription({
    required SubscriptionPlan plan,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiClient.dio.post('/subscription', data: {
        'plan': plan.value,
        'paymentMethod': paymentMethod,
      });
      final subscription = SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obuna yaratishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentIntent>> initiatePayment({
    required SubscriptionPlan plan,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiClient.dio.post('/payment/initiate', data: {
        'plan': plan.value,
        'paymentMethod': paymentMethod,
      });
      final intent = PaymentIntentModel.fromJson(response.data).toEntity();
      return Right(intent);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('To\'lovni boshlashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> confirmPayment({
    required String transactionId,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiClient.dio.post('/payment/confirm', data: {
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
      });
      final subscription = SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('To\'lovni tasdiqlashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> cancelSubscription(String subscriptionId) async {
    try {
      final response = await apiClient.dio.post('/subscription/$subscriptionId/cancel');
      final subscription = SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani bekor qilishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> toggleAutoRenew(String subscriptionId) async {
    try {
      final response = await apiClient.dio.post('/subscription/$subscriptionId/toggle-auto-renew');
      final subscription = SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Avtomatik yangilashni o\'zgartirishda xatolik: $e'));
    }
  }
}

// Subscription Model
class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.paymentMethod,
    required this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'pending',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      autoRenew: json['autoRenew'] ?? true,
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Subscription toEntity() {
    return Subscription(
      id: id,
      userId: userId,
      plan: SubscriptionPlan.fromString(plan),
      status: SubscriptionStatus.fromString(status),
      startDate: startDate,
      endDate: endDate,
      autoRenew: autoRenew,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
    );
  }
}

// Payment Intent Model
class PaymentIntentModel {
  final String id;
  final String paymentUrl;
  final String transactionId;
  final int amount;
  final String currency;
  final DateTime expiresAt;

  PaymentIntentModel({
    required this.id,
    required this.paymentUrl,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.expiresAt,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      id: json['id'] ?? '',
      paymentUrl: json['paymentUrl'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'UZS',
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  PaymentIntent toEntity() {
    return PaymentIntent(
      id: id,
      paymentUrl: paymentUrl,
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      expiresAt: expiresAt,
    );
  }
}
