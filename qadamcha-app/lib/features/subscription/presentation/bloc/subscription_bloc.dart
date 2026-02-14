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
    ));
  }
}
