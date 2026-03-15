import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_monitoring_service.dart';
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
  int _timeLimitMinutes = 30;
  int _usedSeconds = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTimeLimitSettings();
    _usedSeconds = LocalMonitoringService.instance.secondsUsed;
    // Har 30 soniyada used vaqtni yangilash
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _usedSeconds = LocalMonitoringService.instance.secondsUsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Vaqtni formatlash: "2 soat 15 daq" yoki "45 daq"
  String _formatLimitTime(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '$h soat $m daq' : '$h soat';
    }
    return '$minutes daq';
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
                // === PLAN TANLASH ===
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: StatefulBuilder(
                    builder: (context, setPlanState) {
                      final selectedPlan = subState.selectedPlan ?? SubscriptionPlan.monthly;
                      return Row(
                        children: SubscriptionPlan.values.map((plan) {
                          final isSelected = plan == selectedPlan;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.read<SubscriptionBloc>().add(SelectPlanEvent(plan));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${plan.emoji} ${plan.label}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${plan.testMinutes} daqiqa (test)',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textDisabled,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                SizedBox(height: 14.h),

                if (subState.paymentStatus == PaymentStatus.creatingOrder ||
                    subState.paymentStatus == PaymentStatus.paying)
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
                      final plan = subState.selectedPlan ?? SubscriptionPlan.monthly;
                      context.read<SubscriptionBloc>().add(
                        CreateOrderEvent(plan: plan),
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
                  '1 000 so\'m (test)',
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
    final limitHours = _timeLimitMinutes ~/ 60;
    final limitMins = _timeLimitMinutes % 60;
    final usedMinutes = _usedSeconds ~/ 60;
    final remaining = _timeLimitMinutes - usedMinutes;
    final progress = _timeLimitMinutes > 0 
        ? (_usedSeconds / (_timeLimitMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;

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
                          ? '${_formatLimitTime(_timeLimitMinutes)}/kun'
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

          // Vaqt tanlash + Progress
          if (_timeLimitEnabled) ...[
            SizedBox(height: 16.h),

            // Vaqt tanlash
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  Text('Kunlik limit', style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  )),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimePicker(
                        value: limitHours,
                        label: 'soat',
                        onMinus: () {
                          if (limitHours > 0) {
                            final total = (limitHours - 1) * 60 + limitMins;
                            setState(() => _timeLimitMinutes = total < 5 ? 5 : total);
                            _saveTimeLimitSettings();
                          }
                        },
                        onPlus: () {
                          if (limitHours < 5) {
                            final total = (limitHours + 1) * 60 + limitMins;
                            setState(() => _timeLimitMinutes = total > 300 ? 300 : total);
                            _saveTimeLimitSettings();
                          }
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: Text(':', style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontFamily: 'Nunito',
                        )),
                      ),
                      _buildTimePicker(
                        value: limitMins,
                        label: 'daq',
                        onMinus: () {
                          var h = limitHours;
                          var m = limitMins - 5;
                          if (m < 0) { m = 55; h--; }
                          if (h < 0) return;
                          final total = h * 60 + m;
                          if (total >= 5) {
                            setState(() => _timeLimitMinutes = total);
                            _saveTimeLimitSettings();
                          }
                        },
                        onPlus: () {
                          var h = limitHours;
                          var m = limitMins + 5;
                          if (m >= 60) { m = 0; h++; }
                          final total = h * 60 + m;
                          if (total <= 300) {
                            setState(() => _timeLimitMinutes = total);
                            _saveTimeLimitSettings();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Progress bar
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: progress >= 1.0
                    ? const Color(0xFFEF4444).withOpacity(0.06)
                    : progress >= 0.75
                        ? const Color(0xFFF59E0B).withOpacity(0.06)
                        : const Color(0xFF22C55E).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bugungi foydalanish', style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      )),
                      Text(
                        remaining > 0
                            ? 'Qolgan: ${_formatLimitTime(remaining)}'
                            : 'Limit tugagan!',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: progress >= 1.0
                              ? const Color(0xFFEF4444)
                              : progress >= 0.75
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 8.h,
                      backgroundColor: Colors.black.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? const Color(0xFFEF4444)
                            : progress >= 0.75
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatLimitTime(usedMinutes), style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary, fontFamily: 'Nunito',
                      )),
                      Text('${(progress * 100).round()}%', style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w700,
                        color: progress >= 1.0 ? const Color(0xFFEF4444) : AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      )),
                      Text(_formatLimitTime(_timeLimitMinutes), style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary, fontFamily: 'Nunito',
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

  Widget _buildTimePicker({
    required int value,
    required String label,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPlus,
            child: Container(
              width: 48.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
              ),
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  size: 22.sp, color: AppColors.primary),
            ),
          ),
          Container(
            width: 48.w,
            height: 44.h,
            color: AppColors.primary.withOpacity(0.05),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D6A9F),
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onMinus,
            child: Container(
              width: 48.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.r)),
              ),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 22.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textDisabled,
            fontFamily: 'Nunito',
          )),
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
