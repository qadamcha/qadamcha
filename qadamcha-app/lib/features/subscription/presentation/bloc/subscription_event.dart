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
