import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/pages/payment_page.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import 'settings_page.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';

/// Parent Home Page — Bosh sahifa
/// Faqat obuna paneli
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 28.h),
              _buildSubscriptionCard(context),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          ),
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text('\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}', style: TextStyle(fontSize: 24.sp)),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salom! \u{1F44B}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                'Ota-ona paneli',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        // Settings Icon
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.settings_rounded,
              size: 22.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        // To'lov oqimi hozircha ishlatilmaydi
        // Kelajakda qo'shilganda qayta faollashtirish mumkin
        /*
        if (state.paymentStatus == PaymentStatus.orderCreated &&
            state.paymentOrder != null) {
          final bloc = context.read<SubscriptionBloc>();
          final order = state.paymentOrder!;
          final plan = SubscriptionPlan.monthly;

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
        */
      },
      builder: (context, subState) {
        final isPremium = subState.isPremium;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: isPremium
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: (isPremium
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFFFF6B6B))
                    .withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Center(
                      child: Text(
                        isPremium ? '\u{1F451}' : '\u{1F512}',
                        style: TextStyle(fontSize: 32.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Premium obuna' : 'Obuna faol emas',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isPremium
                              ? '${subState.currentSubscription?.remainingDays ?? 30} kun qoldi'
                              : '100 000 so\'m/oy',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.85),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Features list
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Obuna imkoniyatlari',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _featureRow(
                      '\u{1F3AC}',
                      'Barcha multfilmlar',
                      isPremium,
                    ),
                    SizedBox(height: 8.h),
                    _featureRow(
                      '\u{1F3AE}',
                      'Ta\'limiy o\'yinlar',
                      isPremium,
                    ),
                    SizedBox(height: 8.h),
                    _featureRow(
                      '\u{1F6AB}',
                      'Reklamasiz kontent',
                      isPremium,
                    ),
                    SizedBox(height: 8.h),
                    _featureRow(
                      '\u{1F4CA}',
                      'Monitoring va statistika',
                      isPremium,
                    ),
                    SizedBox(height: 8.h),
                    _featureRow(
                      '\u{1F916}',
                      'AI maslahatlar',
                      isPremium,
                    ),
                    SizedBox(height: 8.h),
                    _featureRow(
                      '\u{1F46A}',
                      '5 tagacha bola profili',
                      isPremium,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Action button
              if (!isPremium) ...[
                if (subState.paymentStatus == PaymentStatus.creatingOrder)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      // To'g'ridan-to'g'ri obunani faollashtirish
                      context.read<SubscriptionBloc>().add(
                        ActivateSubscriptionDirectlyEvent(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Text('✅', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'Obuna muvaffaqiyatli faollashtirildi!',
                                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\u{2728}',
                            style: TextStyle(fontSize: 18.sp),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Obunani faollashtirish',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF6B6B),
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (isPremium) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Barcha funksiyalar ochiq',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _featureRow(String emoji, String text, bool isActive) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 16.sp)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
              fontFamily: 'Nunito',
              decoration: isActive ? null : TextDecoration.lineThrough,
              decorationColor: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: Colors.white.withOpacity(isActive ? 1.0 : 0.4),
          size: 18.sp,
        ),
      ],
    );
  }
}
