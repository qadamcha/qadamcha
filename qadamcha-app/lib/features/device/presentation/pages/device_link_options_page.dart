import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import 'qr_scanner_page.dart';
import 'family_code_input_page.dart';

/// Device Link Options Page - matching full_architecture.html design
/// Shows QR scan and Family code options for child device linking
class DeviceLinkOptionsPage extends StatelessWidget {
  const DeviceLinkOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: BackButtonBox(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.1),
                      AppColors.purpleLight.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('🔗', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 14),
              // Title
              const Text(
                'Ota-ona bilan ulaning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kontentga kirish uchun ota-onangiz\ntelefoniga ulanish kerak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 24),
              // QR Scan option
              _LinkOptionCard(
                icon: '📷',
                title: 'QR kod skanerlash',
                subtitle: 'Ota-ona telefonidagi QR kodni skanerlang',
                gradient: AppColors.primaryGradient,
                borderColor: AppColors.primary.withOpacity(0.15),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Family code option
              _LinkOptionCard(
                icon: '🔢',
                title: 'Oila kodi kiritish',
                subtitle: "Ota-onangizdan 6 raqamli kodni so'rang",
                gradient: AppColors.aiGradient,
                borderColor: AppColors.purple.withOpacity(0.15),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FamilyCodeInputPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontFamily: 'Nunito',
                    ),
                    children: [
                      const TextSpan(text: '💡 Ota-onangiz ilovada '),
                      TextSpan(
                        text: 'Sozlamalar → Qurilma ulash',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: " bo'limidan QR kod yoki oila kodini oladi",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkOptionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const _LinkOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: gradient.colors.first.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: gradient.colors.first,
            ),
          ],
        ),
      ),
    );
  }
}
