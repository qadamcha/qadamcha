import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';

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
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
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
                                  vertical: 6.h
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  'Joriy: ${state.currentPlan.label} • ${state.currentSubscription!.remainingDays} kun qoldi',
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
                    ...SubscriptionPlan.values.map((plan) => _PlanCard(
                      plan: plan,
                      isCurrentPlan: state.currentPlan == plan,
                      isSelected: state.selectedPlan == plan,
                      onSelect: () {
                        context.read<SubscriptionBloc>().add(SelectPlanEvent(plan));
                      },
                      onSubscribe: plan == SubscriptionPlan.free 
                          ? null 
                          : () => _showPaymentSheet(context, plan),
                    )),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _PaymentSheet(plan: plan),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isSelected,
    required this.onSelect,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final features = PlanFeatures.features[plan] ?? [];
    final bool isPremiumPlan = plan == SubscriptionPlan.premium;
    
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          gradient: isPremiumPlan ? AppColors.sunsetGradient : null,
          color: isPremiumPlan ? null : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected && !isPremiumPlan
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPremiumPlan ? 0.15 : 0.05),
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
                                color: isPremiumPlan ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              plan.formattedPrice,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isPremiumPlan 
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
                            color: isPremiumPlan 
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Joriy',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isPremiumPlan ? Colors.white : AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  Divider(color: isPremiumPlan ? Colors.white24 : AppColors.divider),
                  SizedBox(height: 12.h),
                  
                  // Features
                  ...features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          feature.included ? Icons.check_circle : Icons.cancel,
                          size: 18.sp,
                          color: isPremiumPlan
                              ? (feature.included ? Colors.white : Colors.white38)
                              : (feature.included ? AppColors.success : AppColors.textSecondary),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            feature.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isPremiumPlan
                                  ? (feature.included ? Colors.white : Colors.white60)
                                  : (feature.included ? AppColors.textPrimary : AppColors.textSecondary),
                              decoration: feature.included ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  // Subscribe Button
                  if (onSubscribe != null && !isCurrentPlan) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPremiumPlan ? Colors.white : AppColors.primary,
                          foregroundColor: isPremiumPlan ? AppColors.primary : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: const Text('Obuna bo\'lish'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Recommended badge
            if (isPremiumPlan)
              Positioned(
                right: 16.w,
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
                  ),
                  child: Text(
                    '⭐ Tavsiya etiladi',
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

class _PaymentSheet extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PaymentSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To\'lov usulini tanlang',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${plan.label} — ${plan.formattedPrice}',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Payment Methods
          _PaymentMethod(
            icon: '💳',
            name: 'Payme',
            description: 'Karta orqali to\'lov',
            onTap: () {
              context.read<SubscriptionBloc>().add(InitiatePaymentEvent(
                plan: plan,
                paymentMethod: 'payme',
              ));
              Navigator.pop(context);
            },
          ),
          _PaymentMethod(
            icon: '📱',
            name: 'Click',
            description: 'Click ilovasi orqali',
            onTap: () {
              context.read<SubscriptionBloc>().add(InitiatePaymentEvent(
                plan: plan,
                paymentMethod: 'click',
              ));
              Navigator.pop(context);
            },
          ),
          _PaymentMethod(
            icon: '🏪',
            name: 'Uzum Bank',
            description: 'Uzum banki kartasi',
            onTap: () {
              context.read<SubscriptionBloc>().add(InitiatePaymentEvent(
                plan: plan,
                paymentMethod: 'uzum',
              ));
              Navigator.pop(context);
            },
          ),
          
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _PaymentMethod extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final VoidCallback onTap;

  const _PaymentMethod({
    required this.icon,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 32.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
