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

class InitiatePaymentEvent extends SubscriptionEvent {
  final SubscriptionPlan plan;
  final String paymentMethod;
  
  const InitiatePaymentEvent({
    required this.plan,
    required this.paymentMethod,
  });
  
  @override
  List<Object?> get props => [plan, paymentMethod];
}

class ConfirmPaymentEvent extends SubscriptionEvent {
  final String transactionId;
  final String paymentMethod;
  
  const ConfirmPaymentEvent({
    required this.transactionId,
    required this.paymentMethod,
  });
  
  @override
  List<Object?> get props => [transactionId, paymentMethod];
}

class CancelSubscriptionEvent extends SubscriptionEvent {
  final String subscriptionId;
  
  const CancelSubscriptionEvent(this.subscriptionId);
  
  @override
  List<Object?> get props => [subscriptionId];
}

class ToggleAutoRenewEvent extends SubscriptionEvent {
  final String subscriptionId;
  
  const ToggleAutoRenewEvent(this.subscriptionId);
  
  @override
  List<Object?> get props => [subscriptionId];
}

class ActivateSubscriptionEvent extends SubscriptionEvent {
  const ActivateSubscriptionEvent();
}
