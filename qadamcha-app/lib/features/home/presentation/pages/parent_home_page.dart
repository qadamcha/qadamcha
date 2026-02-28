import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/pages/payment_page.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'settings_page.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';

/// Parent Home Page — Ko'k-oq premium dizayn
class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  bool _timeLimitEnabled = false;
  int _timeLimitMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadTimeLimitSettings();
  }

  Future<void> _loadTimeLimitSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _timeLimitEnabled = prefs.getBool('time_limit_enabled') ?? false;
        _timeLimitMinutes = prefs.getInt('time_limit_minutes') ?? 5;
      });
    }
  }

  Future<void> _saveTimeLimitSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('time_limit_enabled', _timeLimitEnabled);
    await prefs.setInt('time_limit_minutes', _timeLimitMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D6A9F),
              Color(0xFF1A4A73),
              Color(0xFFF0F4F8),
              Color(0xFFF0F4F8),
            ],
            stops: [0.0, 0.22, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Obuna holatini MongoDB dan qayta tekshirish
              context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            color: const Color(0xFF2D6A9F),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER (gradient ustida) ===
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: _buildHeader(context),
                  ),

                  SizedBox(height: 16.h),

                  // === CONTENT (oq fonda) ===
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildSubscriptionCard(context),
                  ),

                  SizedBox(height: 16.h),

                  // === VAQT LIMITI ===
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildTimeLimitCard(),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState.user?.name ?? 'Ota-ona';

    return Row(
      children: [
        // Back / Role switch
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          ),
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Avatar
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: 26.sp,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salom, $userName! 👋',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Ota-ona paneli',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Settings
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.settings_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
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
          final msg = state.errorMessage!;
          final isAuthError = msg.toLowerCase().contains('autentifikatsiya') ||
              msg.toLowerCase().contains('token') ||
              msg.toLowerCase().contains('tizimga qayta kiring');
          if (isAuthError) {
            // Auth xato — logout qilmasdan, obunani qayta yuklash
            // (refresh lock yangi token oladi va qayta urinadi)
            context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      },
      builder: (context, subState) {
        final isPremium = subState.isPremium;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isPremium
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
                      size: 16.sp,
                      color: isPremium ? AppColors.success : AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isPremium ? 'Premium faol' : 'Bepul rejim',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isPremium ? AppColors.success : AppColors.primary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Icon
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  gradient: isPremium
                      ? const LinearGradient(
                          colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                        )
                      : null,
                  color: isPremium ? null : const Color(0xFFF0F4F8),
                  shape: BoxShape.circle,
                  boxShadow: isPremium
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isPremium ? Icons.diamond_rounded : Icons.workspace_premium_rounded,
                    size: 36.sp,
                    color: isPremium ? Colors.white : AppColors.primary,
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              // Title
              Text(
                isPremium ? 'Premium obuna' : 'Obunangiz yo\'q',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                isPremium
                    ? '${subState.currentSubscription?.remainingDays ?? 30} kun qoldi'
                    : "Barcha imkoniyatlardan foydalaning",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),

              SizedBox(height: 20.h),

              // Divider
              Container(
                height: 1,
                color: const Color(0xFFF0F2F5),
              ),

              SizedBox(height: 16.h),

              // Features grid
              _featureItem(Icons.movie_rounded, 'Multfilmlar', isPremium),
              SizedBox(height: 10.h),
              _featureItem(Icons.videogame_asset_rounded, "Ta'limiy o'yinlar", isPremium),
              SizedBox(height: 10.h),
              _featureItem(Icons.block_rounded, 'Reklamasiz', isPremium),
              SizedBox(height: 10.h),
              _featureItem(Icons.analytics_rounded, 'Monitoring', isPremium),
              SizedBox(height: 10.h),
              _featureItem(Icons.psychology_rounded, 'AI maslahatlar', isPremium),

              SizedBox(height: 20.h),

              // Action button
              if (!isPremium) ...[
                if (subState.paymentStatus == PaymentStatus.creatingOrder)
                  Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      context.read<SubscriptionBloc>().add(
                        CreateOrderEvent(plan: SubscriptionPlan.monthly),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.diamond_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Obunani faollashtirish',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                Text(
                  '1 000 so\'m/oy (test)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],

              if (isPremium) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Barcha funksiyalar ochiq',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
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

  Widget _buildTimeLimitCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Toggle
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _timeLimitEnabled
                      ? AppColors.primary.withOpacity(0.1)
                      : const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.timer_rounded,
                  size: 22.sp,
                  color: _timeLimitEnabled
                      ? AppColors.primary
                      : AppColors.textDisabled,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vaqt nazorati',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      _timeLimitEnabled
                          ? '$_timeLimitMinutes daqiqa/kun'
                          : 'O\'chirilgan',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _timeLimitEnabled,
                onChanged: (value) {
                  setState(() => _timeLimitEnabled = value);
                  _saveTimeLimitSettings();
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),

          // Slider (faqat yoqilgan bo'lsa)
          if (_timeLimitEnabled) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kunlik limit:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '$_timeLimitMinutes daqiqa',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D6A9F),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF2D6A9F),
                      inactiveTrackColor:
                          const Color(0xFF2D6A9F).withOpacity(0.15),
                      thumbColor: const Color(0xFF2D6A9F),
                      overlayColor:
                          const Color(0xFF2D6A9F).withOpacity(0.12),
                      trackHeight: 5,
                      thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 10.r),
                    ),
                    child: Slider(
                      value: _timeLimitMinutes.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() => _timeLimitMinutes = value.round());
                      },
                      onChangeEnd: (value) {
                        _saveTimeLimitSettings();
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 daq', style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textDisabled,
                        fontFamily: 'Nunito',
                      )),
                      Text('20 daq', style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textDisabled,
                        fontFamily: 'Nunito',
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text, bool isActive) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.08)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18.sp,
              color: isActive ? AppColors.primary : AppColors.textDisabled,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
              fontFamily: 'Nunito',
              decoration: isActive ? null : TextDecoration.lineThrough,
              decorationColor: AppColors.textDisabled.withOpacity(0.5),
            ),
          ),
        ),
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isActive ? AppColors.success : AppColors.textDisabled.withOpacity(0.4),
          size: 20.sp,
        ),
      ],
    );
  }
}
