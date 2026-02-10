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
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<ConfirmPaymentEvent>(_onConfirmPayment);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<ToggleAutoRenewEvent>(_onToggleAutoRenew);
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
      )),
    );
  }
  
  Future<void> _onLoadPlans(
    LoadPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    // Plans are loaded from PlanFeatures - static data
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
  
  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.processing));
    
    final result = await repository.initiatePayment(
      plan: event.plan,
      paymentMethod: event.paymentMethod,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (intent) => emit(state.copyWith(
        paymentStatus: PaymentStatus.pending,
        paymentIntent: intent,
      )),
    );
  }
  
  Future<void> _onConfirmPayment(
    ConfirmPaymentEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.confirming));
    
    final result = await repository.confirmPayment(
      transactionId: event.transactionId,
      paymentMethod: event.paymentMethod,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: failure.message,
      )),
      (subscription) => emit(state.copyWith(
        paymentStatus: PaymentStatus.success,
        currentSubscription: subscription,
      )),
    );
  }
  
  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final result = await repository.cancelSubscription(event.subscriptionId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (subscription) => emit(state.copyWith(
        currentSubscription: subscription,
      )),
    );
  }
  
  Future<void> _onToggleAutoRenew(
    ToggleAutoRenewEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final result = await repository.toggleAutoRenew(event.subscriptionId);
    
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (subscription) => emit(state.copyWith(
        currentSubscription: subscription,
      )),
    );
  }
}
