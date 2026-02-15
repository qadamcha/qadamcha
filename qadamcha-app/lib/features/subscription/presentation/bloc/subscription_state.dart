part of 'subscription_bloc.dart';

enum SubscriptionLoadStatus { initial, loading, loaded, error }

enum PaymentStatus {
  initial,
  creatingOrder,
  orderCreated,
  creatingCardToken,
  cardTokenCreated,
  sendingVerifyCode,
  verifyCodeSent,
  verifyingCard,
  cardVerified,
  paying,
  checking,
  success,
  failed,
}

class SubscriptionState extends Equatable {
  final SubscriptionLoadStatus status;
  final Subscription? currentSubscription;
  final List<SubscriptionPlan> availablePlans;
  final SubscriptionPlan? selectedPlan;
  final PaymentStatus paymentStatus;
  final PaymentOrder? paymentOrder;
  final CardToken? cardToken;
  final VerifyCodeResult? verifyCodeResult;
  final PaymentResult? paymentResult;
  final String? errorMessage;

  const SubscriptionState({
    this.status = SubscriptionLoadStatus.initial,
    this.currentSubscription,
    this.availablePlans = const [],
    this.selectedPlan,
    this.paymentStatus = PaymentStatus.initial,
    this.paymentOrder,
    this.cardToken,
    this.verifyCodeResult,
    this.paymentResult,
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
    CardToken? cardToken,
    bool clearCardToken = false,
    VerifyCodeResult? verifyCodeResult,
    bool clearVerifyCodeResult = false,
    PaymentResult? paymentResult,
    bool clearPaymentResult = false,
    String? errorMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      currentSubscription: clearSubscription ? null : (currentSubscription ?? this.currentSubscription),
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentOrder: clearPaymentOrder ? null : (paymentOrder ?? this.paymentOrder),
      cardToken: clearCardToken ? null : (cardToken ?? this.cardToken),
      verifyCodeResult: clearVerifyCodeResult ? null : (verifyCodeResult ?? this.verifyCodeResult),
      paymentResult: clearPaymentResult ? null : (paymentResult ?? this.paymentResult),
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
    cardToken,
    verifyCodeResult,
    paymentResult,
    errorMessage,
  ];
}
