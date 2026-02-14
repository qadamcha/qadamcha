part of 'subscription_bloc.dart';

enum SubscriptionLoadStatus { initial, loading, loaded, error }
enum PaymentStatus { initial, creatingOrder, orderCreated, checking, success, failed }

class SubscriptionState extends Equatable {
  final SubscriptionLoadStatus status;
  final Subscription? currentSubscription;
  final List<SubscriptionPlan> availablePlans;
  final SubscriptionPlan? selectedPlan;
  final PaymentStatus paymentStatus;
  final PaymentOrder? paymentOrder;
  final String? errorMessage;

  const SubscriptionState({
    this.status = SubscriptionLoadStatus.initial,
    this.currentSubscription,
    this.availablePlans = const [],
    this.selectedPlan,
    this.paymentStatus = PaymentStatus.initial,
    this.paymentOrder,
    this.errorMessage,
  });

  SubscriptionState copyWith({
    SubscriptionLoadStatus? status,
    Subscription? currentSubscription,
    bool clearSubscription = false,
    List<SubscriptionPlan>? availablePlans,
    SubscriptionPlan? selectedPlan,
    PaymentStatus? paymentStatus,
    PaymentOrder? paymentOrder,
    bool clearPaymentOrder = false,
    String? errorMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      currentSubscription: clearSubscription ? null : (currentSubscription ?? this.currentSubscription),
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentOrder: clearPaymentOrder ? null : (paymentOrder ?? this.paymentOrder),
      errorMessage: errorMessage,
    );
  }

  bool get isActive => currentSubscription?.isActive ?? false;
  bool get isPremium => currentSubscription?.isPremium ?? false;
  SubscriptionPlan? get currentPlan => currentSubscription?.plan;

  @override
  List<Object?> get props => [
    status,
    currentSubscription,
    availablePlans,
    selectedPlan,
    paymentStatus,
    paymentOrder,
    errorMessage,
  ];
}
