import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(const SubscriptionState()) {
    on<LoadSubscriptionEvent>(_onLoadSubscription);
    on<LoadPlansEvent>(_onLoadPlans);
    on<SelectPlanEvent>(_onSelectPlan);
    on<CreateOrderEvent>(_onCreateOrder);
    on<CheckOrderEvent>(_onCheckOrder);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<ResetPaymentEvent>(_onResetPayment);
    on<ActivateSubscriptionDirectlyEvent>(_onActivateDirectly);
    // Subscribe API events
    on<CreateCardTokenEvent>(_onCreateCardToken);
    on<GetVerifyCodeEvent>(_onGetVerifyCode);
    on<VerifyCardEvent>(_onVerifyCard);
    on<PayWithTokenEvent>(_onPayWithToken);
  }

  Future<void> _onLoadSubscription(
    LoadSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionLoadStatus.loading));

    final result = await repository.getCurrentSubscription();

    result.fold(
      (failure) => emit(state.copyWith(
        status: SubscriptionLoadStatus.error,
        errorMessage: failure.message,
      )),
      (subscription) => emit(state.copyWith(
        status: SubscriptionLoadStatus.loaded,
        currentSubscription: subscription,
        clearSubscription: subscription == null,
      )),
    );
  }

  Future<void> _onLoadPlans(
    LoadPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(
      availablePlans: SubscriptionPlan.values.toList(),
    ));
  }

  void _onSelectPlan(
    SelectPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(selectedPlan: event.plan));
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.creatingOrder));

    final result = await repository.createOrder(plan: event.plan);

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (order) => emit(state.copyWith(
        paymentStatus: PaymentStatus.orderCreated,
        paymentOrder: order,
      )),
    );
  }

  Future<void> _onCheckOrder(
    CheckOrderEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.checking));

    final result = await repository.checkOrder(event.orderId);

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (status) {
        if (status.paid) {
          emit(state.copyWith(
            paymentStatus: PaymentStatus.success,
            currentSubscription: status.subscription,
          ));
        } else {
          emit(state.copyWith(paymentStatus: PaymentStatus.initial));
        }
      },
    );
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final result = await repository.cancelSubscription();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        clearSubscription: true,
      )),
    );
  }

  void _onResetPayment(
    ResetPaymentEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(
      paymentStatus: PaymentStatus.initial,
      clearPaymentOrder: true,
      clearCardToken: true,
      clearVerifyCodeResult: true,
      clearPaymentResult: true,
    ));
  }

  /// To'g'ridan-to'g'ri obunani faollashtirish (to'lovsiz)
  void _onActivateDirectly(
    ActivateSubscriptionDirectlyEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    final now = DateTime.now();
    final subscription = Subscription(
      id: 'local_${now.millisecondsSinceEpoch}',
      userId: 'local_user',
      plan: SubscriptionPlan.monthly,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      createdAt: now,
    );
    emit(state.copyWith(
      status: SubscriptionLoadStatus.loaded,
      currentSubscription: subscription,
    ));
  }

  // ============= Subscribe API Handlers =============

  Future<void> _onCreateCardToken(
    CreateCardTokenEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.creatingCardToken));

    final result = await repository.createCardToken(
      cardNumber: event.cardNumber,
      expire: event.expire,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (cardToken) => emit(state.copyWith(
        paymentStatus: PaymentStatus.cardTokenCreated,
        cardToken: cardToken,
      )),
    );
  }

  Future<void> _onGetVerifyCode(
    GetVerifyCodeEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.sendingVerifyCode));

    final result = await repository.getVerifyCode(event.token);

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (verifyResult) => emit(state.copyWith(
        paymentStatus: PaymentStatus.verifyCodeSent,
        verifyCodeResult: verifyResult,
      )),
    );
  }

  Future<void> _onVerifyCard(
    VerifyCardEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.verifyingCard));

    final result = await repository.verifyCard(
      token: event.token,
      code: event.code,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (cardToken) => emit(state.copyWith(
        paymentStatus: PaymentStatus.cardVerified,
        cardToken: cardToken,
      )),
    );
  }

  Future<void> _onPayWithToken(
    PayWithTokenEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.paying));

    final result = await repository.payWithToken(
      orderId: event.orderId,
      token: event.token,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (paymentResult) {
        if (paymentResult.success) {
          emit(state.copyWith(
            paymentStatus: PaymentStatus.success,
            paymentResult: paymentResult,
            currentSubscription: paymentResult.subscription,
          ));
        } else {
          emit(state.copyWith(
            paymentStatus: PaymentStatus.failed,
            errorMessage: paymentResult.message ?? 'To\'lov amalga oshmadi',
          ));
        }
      },
    );
  }
}
