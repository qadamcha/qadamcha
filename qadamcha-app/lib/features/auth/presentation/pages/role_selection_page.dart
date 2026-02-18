import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';
import 'package:qadamcha_app/core/widgets/gradient_button.dart';
import 'package:qadamcha_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/parent_pin_page.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/child_pin_page.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/phone_page.dart';
import 'package:qadamcha_app/features/home/presentation/pages/child_home_page.dart';
import 'package:qadamcha_app/features/home/presentation/pages/parent_home_page.dart';
import 'package:qadamcha_app/features/subscription/presentation/bloc/subscription_bloc.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                'Kim foydalanmoqda?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Iltimos, o\'z profilingizni tanlang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(flex: 3),
              _buildRoleCard(
                context,
                title: 'Ota-ona',
                subtitle: 'PIN kod orqali kirish',
                icon: '👨‍👩‍👧',
                color: AppColors.primary,
                onTap: () => _onParentSelected(context),
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                context,
                title: 'Bolajon',
                subtitle: 'Bolalar rejimiga kirish',
                icon: '👶',
                color: AppColors.secondary,
                onTap: () => _onChildSelected(context),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  bool _isLoggedIn(AuthStatus status) {
    return status == AuthStatus.authenticated ||
        status == AuthStatus.registered ||
        status == AuthStatus.pinVerified ||
        status == AuthStatus.pinReset;
  }

  void _onParentSelected(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (_isLoggedIn(authState.status)) {
      // Obunani yuklash
      context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
      // Token bor — PIN orqali kirish
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentPinPage()),
      );
    } else {
      // Token yo'q — ro'yxatdan o'tish
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhonePage()),
      );
    }
  }

  void _onChildSelected(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (_isLoggedIn(authState.status)) {
      // Obunani yuklash
      context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
      
      // Agar bu qurilma 'child' rejimida bo'lsa yoki parent qurilmasidan
      // "Bola" tanlansa — to'g'ridan-to'g'ri bola sahifasiga
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChildHomePage(),
        ),
      );
    } else {
      // Token yo'q — avval ro'yxatdan o'tish kerak
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('⚠️ ', style: TextStyle(fontSize: 24)),
              Text('Diqqat', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Avval ota-ona sifatida ro\'yxatdan o\'ting.\n\nBuning uchun "Ota-ona" tugmasini bosing.',
            style: TextStyle(fontFamily: 'Nunito', height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tushundim',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
