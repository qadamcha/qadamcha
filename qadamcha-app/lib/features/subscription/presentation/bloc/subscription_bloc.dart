import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../../../core/errors/failures.dart';
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
    }
    
    // MUHIM: loading holatida mavjud subscription'ni SAQLAB qolish
    // Aks holda ChildHomePage "Obuna faol emas" ko'rsatadi
    if (state.currentSubscription == null && localSub == null) {
      emit(state.copyWith(status: SubscriptionLoadStatus.loading));
    }

    // 2. Backend bilan sinxronlash
    final result = await repository.getCurrentSubscription();

    result.fold(
      (failure) {
        // Backend xato — mavjud subscription'ni saqlab qolish
        // Agar local ham, state ham bo'sh bo'lsa, loaded sifatida belgilash
        if (state.status != SubscriptionLoadStatus.loaded) {
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
          ));
        }
      },
      (subscription) {
        // Backend javobini davolash
        if (subscription != null) {
          // Backend'da obuna bor — yangilash va local'ga saqlash
          _saveSubscriptionLocally(subscription);
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            currentSubscription: subscription,
          ));
        } else {
          // Backend'da obuna yo'q — lekin local faol bo'lsa, SAQLAB QOLISH
          // (Backend bilan sync muammosi bo'lishi mumkin)
          final currentSub = state.currentSubscription;
          if (currentSub != null && currentSub.isActive) {
            // Local obuna hali faol — o'chirmaymiz
            emit(state.copyWith(
              status: SubscriptionLoadStatus.loaded,
            ));
          } else {
            // Haqiqatan ham obuna yo'q
            LocalMonitoringService.instance.clearSubscription();
            emit(state.copyWith(
              status: SubscriptionLoadStatus.loaded,
              clearSubscription: true,
            ));
          }
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
    final result = await repository.activateTestSubscription(plan: event.plan.value);

    result.fold(
      (failure) {
        if (failure is AuthFailure) {
          // Auth xato (401) — foydalanuvchiga tizimga qayta kirish kerakligini aytish
          emit(state.copyWith(
            paymentStatus: PaymentStatus.failed,
            errorMessage: 'Sessiya tugadi. Iltimos, tizimga qayta kiring.',
          ));
        } else {
          // Network/Server xato — offline fallback (faqat local, 5 daqiqalik test)
          final now = DateTime.now();
          final subscription = Subscription(
            id: 'local_${now.millisecondsSinceEpoch}',
            userId: 'local_user',
            plan: event.plan,
            status: SubscriptionStatus.active,
            startDate: now,
            endDate: now.add(Duration(minutes: event.plan.testMinutes)),
            createdAt: now,
          );
          _saveSubscriptionLocally(subscription);
          emit(state.copyWith(
            status: SubscriptionLoadStatus.loaded,
            paymentStatus: PaymentStatus.success,
            currentSubscription: subscription,
          ));
        }
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
