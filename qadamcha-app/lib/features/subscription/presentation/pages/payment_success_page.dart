import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';

/// Payment Success Page - Shown after successful payment
/// Matching full_architecture.html design with celebration
class PaymentSuccessPage extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentSuccessPage({super.key, required this.plan});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated success icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎉', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Tabriklaymiz!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Siz ${widget.plan.label} obunasini\nmuvaffaqiyatli sotib oldingiz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Plan benefits
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow('📺', 'Cheksiz multfilmlar'),
                      _buildBenefitRow('🎮', 'Barcha o\'yinlar'),
                      _buildBenefitRow('🤖', 'AI Yordamchi'),
                      _buildBenefitRow('📊', 'To\'liq monitoring'),
                      _buildBenefitRow('👨‍👩‍👧', 'Cheksiz bolalar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Receipt info
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('✅', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To\'lov tasdiqlandi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kvitansiya SMS orqali yuborildi',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.success.withValues(alpha: 0.8),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Continue button
              GradientButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationPage()),
                    (route) => false,
                  );
                },
                text: 'Bosh sahifaga o\'tish →',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
