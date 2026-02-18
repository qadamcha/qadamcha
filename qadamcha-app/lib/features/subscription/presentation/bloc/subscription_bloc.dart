import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../../../core/services/local_monitoring_service.dart';

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
    // 1. Local-first: avval keshdan yuklash (tezkor UX)
    final localSub = LocalMonitoringService.instance.getSubscription();
    if (localSub != null) {
      try {
        final cachedSub = Subscription(
          id: localSub['id'] ?? '',
          userId: localSub['userId'] ?? '',
          plan: SubscriptionPlan.fromString(localSub['plan'] ?? 'monthly'),
          status: SubscriptionStatus.fromString(localSub['status'] ?? 'active'),
          startDate: DateTime.tryParse(localSub['startDate'] ?? '') ?? DateTime.now(),
          endDate: DateTime.tryParse(localSub['endDate'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.tryParse(localSub['createdAt'] ?? '') ?? DateTime.now(),
        );
        // Muddat o'tmaganmi tekshirish
        if (cachedSub.isActive) {
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            currentSubscription: cachedSub,
          ));
        }
      } catch (_) {}
    } else {
      emit(state.copyWith(status: SubscriptionLoadStatus.loading));
    }

    // 2. Backend bilan sinxronlash
    final result = await repository.getCurrentSubscription();

    result.fold(
      (failure) {
        // Backend xato — agar local allaqachon yuklangan bo'lsa, shuni qoldiramiz
        if (state.status != SubscriptionLoadStatus.loaded) {
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            clearSubscription: localSub == null,
          ));
        }
      },
      (subscription) {
        // Backend javobini local'ga saqlash va state'ni yangilash
        if (subscription != null) {
          _saveSubscriptionLocally(subscription);
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            currentSubscription: subscription,
          ));
        } else {
          // Backend'da obuna yo'q — local keshni tozalash
          LocalMonitoringService.instance.clearSubscription();
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            clearSubscription: true,
          ));
        }
      },
    );
  }

  void _saveSubscriptionLocally(Subscription sub) {
    LocalMonitoringService.instance.saveSubscription({
      'id': sub.id,
      'userId': sub.userId,
      'plan': sub.plan.value,
      'status': sub.status.value,
      'startDate': sub.startDate.toIso8601String(),
      'endDate': sub.endDate.toIso8601String(),
      'createdAt': sub.createdAt.toIso8601String(),
    });
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

  /// To'g'ridan-to'g'ri obunani faollashtirish (test rejimi)
  Future<void> _onActivateDirectly(
    ActivateSubscriptionDirectlyEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.paying));

    // Backend'ga so'rov yuborish
    final result = await repository.activateTestSubscription();

    result.fold(
      (failure) {
        // Backend xato — offline fallback (faqat local)
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
        _saveSubscriptionLocally(subscription);
        emit(state.copyWith(
          status: SubscriptionLoadStatus.loaded,
          paymentStatus: PaymentStatus.success,
          currentSubscription: subscription,
        ));
      },
      (subscription) {
        // Backend muvaffaqiyatli — saqlash
        _saveSubscriptionLocally(subscription);
        emit(state.copyWith(
          status: SubscriptionLoadStatus.loaded,
          paymentStatus: PaymentStatus.success,
          currentSubscription: subscription,
        ));
      },
    );
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
          if (paymentResult.subscription != null) {
            _saveSubscriptionLocally(paymentResult.subscription!);
          }
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
