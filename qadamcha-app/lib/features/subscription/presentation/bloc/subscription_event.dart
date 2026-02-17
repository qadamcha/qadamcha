part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionEvent extends SubscriptionEvent {}

class LoadPlansEvent extends SubscriptionEvent {}

class SelectPlanEvent extends SubscriptionEvent {
  final SubscriptionPlan plan;

  const SelectPlanEvent(this.plan);

  @override
  List<Object?> get props => [plan];
}

class CreateOrderEvent extends SubscriptionEvent {
  final SubscriptionPlan plan;

  const CreateOrderEvent({required this.plan});

  @override
  List<Object?> get props => [plan];
}

class CheckOrderEvent extends SubscriptionEvent {
  final String orderId;

  const CheckOrderEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class CancelSubscriptionEvent extends SubscriptionEvent {}

class ResetPaymentEvent extends SubscriptionEvent {}

/// To'g'ridan-to'g'ri obunani faollashtirish (to'lovsiz, hozircha)
class ActivateSubscriptionDirectlyEvent extends SubscriptionEvent {}

// ============= Subscribe API Events =============

/// Karta tokenini yaratish
class CreateCardTokenEvent extends SubscriptionEvent {
  final String cardNumber;
  final String expire;

  const CreateCardTokenEvent({
    required this.cardNumber,
    required this.expire,
  });

  @override
  List<Object?> get props => [cardNumber, expire];
}

/// SMS tasdiqlash kodini so'rash
class GetVerifyCodeEvent extends SubscriptionEvent {
  final String token;

  const GetVerifyCodeEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

/// Kartani SMS kod bilan tasdiqlash
class VerifyCardEvent extends SubscriptionEvent {
  final String token;
  final String code;

  const VerifyCardEvent({
    required this.token,
    required this.code,
  });

  @override
  List<Object?> get props => [token, code];
}

/// To'lov qilish
class PayWithTokenEvent extends SubscriptionEvent {
  final String orderId;
  final String token;

  const PayWithTokenEvent({
    required this.orderId,
    required this.token,
  });

  @override
  List<Object?> get props => [orderId, token];
}
