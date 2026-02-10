import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../subscription/presentation/pages/subscription_plans_page.dart';

/// Subscription Expired Page - shown when subscription ends
/// Matching full_architecture.html design with sad icon and upgrade prompt
class SubscriptionExpiredPage extends StatelessWidget {
  const SubscriptionExpiredPage({super.key});

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
              // Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text('😢', style: TextStyle(fontSize: 54)),
                ),
              ),
              const SizedBox(height: 28),
              // Title
              const Text(
                'Obuna muddati tugadi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Farzandingiz ilova kontentidan\nfoydalanish uchun obunani yangilang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 36),
              // What you're missing
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Siz quyidagilarni yo\'qotyapsiz:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildMissingItem('📺', 'Cheksiz multfilmlar'),
                    _buildMissingItem('🎮', 'Ta\'limiy o\'yinlar'),
                    _buildMissingItem('🤖', 'AI Yordamchi'),
                    _buildMissingItem('📊', 'Monitoring tizimi'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Upgrade Button
              GradientButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansPage(),
                    ),
                  );
                },
                text: 'Obunani yangilash 💎',
                variant: GradientButtonVariant.gold,
              ),
              const SizedBox(height: 16),
              // Later button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Keyinroq',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissingItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
