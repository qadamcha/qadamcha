part of 'subscription_bloc.dart';

enum SubscriptionLoadStatus { initial, loading, loaded, error }
enum PaymentStatus { initial, processing, pending, confirming, success, failed }

class SubscriptionState extends Equatable {
  final SubscriptionLoadStatus status;
  final Subscription? currentSubscription;
  final List<SubscriptionPlan> availablePlans;
  final SubscriptionPlan? selectedPlan;
  final PaymentStatus paymentStatus;
  final PaymentIntent? paymentIntent;
  final String? errorMessage;
  
  const SubscriptionState({
    this.status = SubscriptionLoadStatus.initial,
    this.currentSubscription,
    this.availablePlans = const [],
    this.selectedPlan,
    this.paymentStatus = PaymentStatus.initial,
    this.paymentIntent,
    this.errorMessage,
  });
  
  SubscriptionState copyWith({
    SubscriptionLoadStatus? status,
    Subscription? currentSubscription,
    List<SubscriptionPlan>? availablePlans,
    SubscriptionPlan? selectedPlan,
    PaymentStatus? paymentStatus,
    PaymentIntent? paymentIntent,
    String? errorMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentIntent: paymentIntent ?? this.paymentIntent,
      errorMessage: errorMessage,
    );
  }
  
  bool get isPremium => currentSubscription?.isPremium ?? false;
  bool get isActive => currentSubscription?.isActive ?? false;
  SubscriptionPlan get currentPlan => 
      currentSubscription?.plan ?? SubscriptionPlan.free;
  
  @override
  List<Object?> get props => [
    status,
    currentSubscription,
    availablePlans,
    selectedPlan,
    paymentStatus,
    paymentIntent,
    errorMessage,
  ];
}
