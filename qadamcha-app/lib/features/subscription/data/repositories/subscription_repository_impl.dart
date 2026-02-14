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
      final response = await apiClient.dio.get('/subscription');
      if (response.data['hasSubscription'] != true ||
          response.data['subscription'] == null) {
        return const Right(null);
      }
      final subscription =
          SubscriptionModel.fromJson(response.data['subscription']).toEntity();
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
      final subscriptions =
          data.map((json) => SubscriptionModel.fromJson(json).toEntity()).toList();
      return Right(subscriptions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obuna tarixini olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getAvailablePlans() async {
    return Right(SubscriptionPlan.values.toList());
  }

  @override
  Future<Either<Failure, PaymentOrder>> createOrder({
    required SubscriptionPlan plan,
  }) async {
    try {
      final response = await apiClient.dio.post('/subscription/create', data: {
        'plan': plan.value,
      });
      final data = response.data;
      return Right(PaymentOrder(
        orderId: data['orderId'] ?? '',
        checkoutUrl: data['checkoutUrl'] ?? '',
        amount: data['amount'] ?? 0,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Buyurtma yaratishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, OrderStatus>> checkOrder(String orderId) async {
    try {
      final response =
          await apiClient.dio.get('/subscription/check/$orderId');
      final data = response.data;
      Subscription? subscription;
      if (data['subscription'] != null) {
        subscription =
            SubscriptionModel.fromJson(data['subscription']).toEntity();
      }
      return Right(OrderStatus(
        status: data['status'] ?? 'pending',
        paid: data['paid'] == true,
        subscription: subscription,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('To\'lov holatini tekshirishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await apiClient.dio.post('/subscription/cancel');
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani bekor qilishda xatolik: $e'));
    }
  }
}

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
      plan: json['plan'] ?? 'monthly',
      status: json['status'] ?? 'pending',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      autoRenew: json['autoRenew'] ?? false,
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
