import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../bloc/subscription_bloc.dart';
import 'payment_page.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>()
      ..add(LoadSubscriptionEvent())
      ..add(LoadPlansEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state.paymentStatus == PaymentStatus.orderCreated &&
              state.paymentOrder != null) {
            final bloc = context.read<SubscriptionBloc>();
            final order = state.paymentOrder!;
            final plan = state.selectedPlan ?? SubscriptionPlan.monthly;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: PaymentPage(
                    plan: plan,
                    orderId: order.orderId,
                  ),
                ),
              ),
            ).then((_) {
              // To'lov sahifasi yopilganda obuna holatini yangilash
              bloc.add(ResetPaymentEvent());
              bloc.add(LoadSubscriptionEvent());
            });
          }

          if (state.paymentStatus == PaymentStatus.failed &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 180.h,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Obuna Rejalari',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            if (state.currentSubscription != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  'Joriy: ${state.currentPlan?.label ?? ""} • ${state.currentSubscription!.remainingDays} kun qoldi',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Plans Grid
              SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...SubscriptionPlan.values.map(
                      (plan) => _PlanCard(
                        plan: plan,
                        isCurrentPlan: state.currentPlan == plan,
                        isSelected: state.selectedPlan == plan,
                        isLoading: state.paymentStatus ==
                                PaymentStatus.creatingOrder &&
                            state.selectedPlan == plan,
                        onSelect: () {
                          context
                              .read<SubscriptionBloc>()
                              .add(SelectPlanEvent(plan));
                        },
                        onSubscribe: () => _onSubscribe(context, plan),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSubscribe(BuildContext context, SubscriptionPlan plan) {
    context.read<SubscriptionBloc>()
      ..add(SelectPlanEvent(plan))
      ..add(CreateOrderEvent(plan: plan));
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onSelect;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isSelected,
    required this.isLoading,
    required this.onSelect,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final features = PlanFeatures.features[plan] ?? [];
    final bool isRecommended = plan == SubscriptionPlan.yearly;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          gradient: isRecommended ? AppColors.sunsetGradient : null,
          color: isRecommended ? null : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected && !isRecommended
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRecommended ? 0.15 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        plan.emoji,
                        style: TextStyle(fontSize: 32.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.label,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: isRecommended
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              plan.formattedPrice,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isRecommended
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentPlan)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isRecommended
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Joriy',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isRecommended
                                  ? Colors.white
                                  : AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  Divider(
                      color:
                          isRecommended ? Colors.white24 : AppColors.divider),
                  SizedBox(height: 12.h),

                  // Features
                  ...features.map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Icon(
                              feature.included
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 18.sp,
                              color: isRecommended
                                  ? (feature.included
                                      ? Colors.white
                                      : Colors.white38)
                                  : (feature.included
                                      ? AppColors.success
                                      : AppColors.textSecondary),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                feature.title,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isRecommended
                                      ? (feature.included
                                          ? Colors.white
                                          : Colors.white60)
                                      : (feature.included
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary),
                                  decoration: feature.included
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  // Subscribe Button
                  if (!isCurrentPlan) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isRecommended ? Colors.white : AppColors.primary,
                          foregroundColor:
                              isRecommended ? AppColors.primary : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isRecommended
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              )
                            : const Text('Obuna bo\'lish'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Recommended badge
            if (isRecommended)
              Positioned(
                right: 16.w,
                top: 0,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(8.r)),
                  ),
                  child: Text(
                    'Tavsiya etiladi',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
