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
      final response = await apiClient.get('/subscription');
      if (response.data['hasSubscription'] != true ||
          response.data['subscription'] == null) {
        return const Right(null);
      }
      final subscription =
          SubscriptionModel.fromJson(response.data['subscription']).toEntity();
      return Right(subscription);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani olishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Subscription>>> getSubscriptionHistory() async {
    try {
      final response = await apiClient.get('/subscription/history');
      final List<dynamic> data = response.data['subscriptions'] ?? [];
      final subscriptions =
          data.map((json) => SubscriptionModel.fromJson(json).toEntity()).toList();
      return Right(subscriptions);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
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
      final response = await apiClient.post('/subscription/create', data: {
        'plan': plan.value,
      });
      final data = response.data;
      return Right(PaymentOrder(
        orderId: data['orderId'] ?? '',
        amount: data['amount'] ?? 0,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
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
          await apiClient.dio.get('/payme/status/$orderId');
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
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('To\'lov holatini tekshirishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await apiClient.dio.post('/subscription/cancel', data: {});
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani bekor qilishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> activateTestSubscription({String plan = 'monthly'}) async {
    try {
      final response = await apiClient.post('/subscription/activate-test', data: {'plan': plan});
      final data = response.data;
      if (data['subscription'] != null) {
        final subscription =
            SubscriptionModel.fromJson(data['subscription']).toEntity();
        return Right(subscription);
      }
      return Left(ServerFailure('Obuna ma\'lumotlari kelmadi'));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Obunani faollashtirishda xatolik: $e'));
    }
  }

  // ============= Subscribe API Methods =============

  @override
  Future<Either<Failure, CardToken>> createCardToken({
    required String cardNumber,
    required String expire,
  }) async {
    try {
      final response = await apiClient.post('/payme/card/create', data: {
        'cardNumber': cardNumber,
        'expire': expire,
      });
      final data = response.data;
      return Right(CardToken(
        token: data['token'] ?? '',
        maskedNumber: data['card']?['number'] ?? '',
        expire: data['card']?['expire'] ?? '',
        type: data['card']?['type'] ?? 'unknown',
        recurrent: data['card']?['recurrent'] ?? false,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Karta tokenini yaratishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, VerifyCodeResult>> getVerifyCode(String token) async {
    try {
      final response = await apiClient.post('/payme/card/verify-code', data: {
        'token': token,
      });
      final data = response.data;
      return Right(VerifyCodeResult(
        sent: data['sent'] ?? false,
        phone: data['phone'] ?? '',
        wait: data['wait'] ?? 60,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('SMS kod yuborishda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, CardToken>> verifyCard({
    required String token,
    required String code,
  }) async {
    try {
      final response = await apiClient.post('/payme/card/verify', data: {
        'token': token,
        'code': code,
      });
      final data = response.data;
      final card = data['card'] ?? {};
      return Right(CardToken(
        token: card['token'] ?? token,
        maskedNumber: card['number'] ?? '',
        expire: card['expire'] ?? '',
        type: card['type'] ?? 'unknown',
        recurrent: card['recurrent'] ?? false,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Kartani tasdiqlashda xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> payWithToken({
    required String orderId,
    required String token,
  }) async {
    try {
      final response = await apiClient.post('/payme/pay', data: {
        'orderId': orderId,
        'token': token,
      });
      final data = response.data;
      Subscription? subscription;
      if (data['subscription'] != null) {
        subscription =
            SubscriptionModel.fromJson(data['subscription']).toEntity();
      }
      return Right(PaymentResult(
        success: data['success'] == true,
        transactionId: data['transaction']?['id'],
        receiptId: data['transaction']?['receiptId'],
        state: data['transaction']?['state'],
        message: data['message'],
        subscription: subscription,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('To\'lovda xatolik: $e'));
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
