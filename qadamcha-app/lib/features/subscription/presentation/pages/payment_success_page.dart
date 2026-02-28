import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';

/// Payment Success Page — Optimized confetti animation
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
  late Animation<double> _confettiAnimation;

  // Confetti ma'lumotlari initState da bir marta hisoblanadi
  late final List<_ConfettiData> _confettiItems;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1.0, curve: Curves.linear),
      ),
    );

    // Confetti ma'lumotlarini oldindan hisoblash (build da emas)
    final random = math.Random(42);
    final colors = [
      const Color(0xFF2D6A9F),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFF4A90D9),
      const Color(0xFF6BB5F0),
      const Color(0xFF1A4A73),
    ];
    _confettiItems = List.generate(15, (i) {
      return _ConfettiData(
        leftFraction: random.nextDouble(),
        delay: random.nextDouble() * 0.3,
        size: 6.0 + random.nextDouble() * 6,
        color: colors[random.nextInt(colors.length)],
        isCircle: random.nextBool(),
        index: i,
      );
    });

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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti — faqat 1 ta AnimatedBuilder, 15 ta Positioned
            AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, _) {
                final t = _confettiAnimation.value;
                if (t <= 0) return const SizedBox.shrink();
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                return Stack(
                  children: _confettiItems.map((item) {
                    final itemT = (t - item.delay).clamp(0.0, 1.0);
                    if (itemT <= 0) return const SizedBox.shrink();

                    final y = -20 + itemT * (screenHeight + 40);
                    final x = item.leftFraction * screenWidth +
                        math.sin(itemT * math.pi * 3 + item.index) * 25;
                    final opacity =
                        itemT < 0.7 ? 1.0 : (1.0 - (itemT - 0.7) / 0.3);

                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: itemT * math.pi * 3,
                          child: Container(
                            width: item.size,
                            height:
                                item.isCircle ? item.size : item.size * 0.4,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(
                                  item.isCircle ? item.size : 2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Success icon
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
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 36,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  // Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Tabriklaymiz!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      '${widget.plan.label} obunasi muvaffaqiyatli faollashtirildi!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Payment details card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildPaymentDetailsCard(),
                  ),
                  const SizedBox(height: 20),

                  // Benefits card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBenefitsCard(),
                  ),

                  const Spacer(flex: 2),

                  // Continue button
                  GradientButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainNavigationPage()),
                        (route) => false,
                      );
                    },
                    text: 'Bosh sahifaga  →',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'To\'lov tasdiqlandi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Muvaffaqiyat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildDetailRow('Tarif rejasi', widget.plan.label),
          const SizedBox(height: 8),
          _buildDetailRow('Summa', widget.plan.formattedPrice),
          const SizedBox(height: 8),
          _buildDetailRow('Muddat', widget.plan.periodLabel),
          const SizedBox(height: 8),
          _buildDetailRow('To\'lov usuli', 'Payme'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sizga ochilgan imkoniyatlar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.live_tv_rounded, const Color(0xFF2D6A9F),
              'Cheksiz multfilmlar'),
          _buildBenefitRow(Icons.sports_esports_rounded,
              const Color(0xFF22C55E), 'Barcha o\'yinlar'),
          _buildBenefitRow(Icons.smart_toy_rounded, const Color(0xFF7C4DFF),
              'AI Yordamchi'),
          _buildBenefitRow(Icons.bar_chart_rounded, const Color(0xFFF59E0B),
              'To\'liq monitoring'),
          _buildBenefitRow(Icons.family_restroom_rounded,
              const Color(0xFF4A90D9), 'Cheksiz bolalar profili'),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
        ],
      ),
    );
  }
}

/// Confetti data — oldindan hisoblanadi, har frame da qayta hisoblanmaydi
class _ConfettiData {
  final double leftFraction;
  final double delay;
  final double size;
  final Color color;
  final bool isCircle;
  final int index;

  const _ConfettiData({
    required this.leftFraction,
    required this.delay,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.index,
  });
}
