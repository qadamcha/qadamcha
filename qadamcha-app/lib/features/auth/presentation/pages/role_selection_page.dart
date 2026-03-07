import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';
import 'package:qadamcha_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/parent_pin_page.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/phone_page.dart';
import 'package:qadamcha_app/features/child/presentation/bloc/child_bloc.dart';
import 'package:qadamcha_app/features/device/presentation/bloc/device_bloc.dart';
import 'package:qadamcha_app/features/home/presentation/pages/child_home_page.dart';
import 'package:qadamcha_app/features/subscription/presentation/bloc/subscription_bloc.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      try {
        final authState = context.read<AuthBloc>().state;
        if (_isLoggedIn(authState.status)) {
          context.read<DeviceBloc>().add(CheckDeviceStatusEvent());
        }
      } catch (_) {
        // Provider topilmasa xavfsiz o'tkazib yuborish
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.family_restroom_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 8),
              const Text(
                'Iltimos, o\'z profilingizni tanlang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(flex: 2),
              _buildRoleCard(
                context,
                title: 'Ota-ona',
                subtitle: 'PIN kod orqali kirish',
                iconData: Icons.admin_panel_settings_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                ),
                onTap: () => _onParentSelected(context),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: 'Bolajon',
                subtitle: 'Bolalar rejimiga kirish',
                iconData: Icons.child_care_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF6BB5F0)],
                ),
                onTap: () => _onChildSelected(context),
              ),
              const Spacer(flex: 3),
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
    required IconData iconData,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(iconData, size: 28, color: Colors.white),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 16,
              ),
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
        status == AuthStatus.pinReset ||
        status == AuthStatus.error ||    // PIN xatosi ≠ logout
        status == AuthStatus.loading;    // Yuklanmoqda ≠ logout
  }

  /// Qurilma o'chirilganligini tekshirish (keshdan — darhol)
  /// Fondan yangi status yuklaydi (keyingi safar uchun)
  bool _checkDeviceRemoved(BuildContext context) {
    try {
      final deviceBloc = context.read<DeviceBloc>();
      final deviceState = deviceBloc.state;
      
      // Fondan yangi status yuklash (keyingi safar uchun)
      deviceBloc.add(CheckDeviceStatusEvent());
      
      if (deviceState.isCurrentDeviceRemoved) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhonePage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu qurilma akkauntdan o\'chirilgan'),
            backgroundColor: AppColors.error,
          ),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _onParentSelected(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (_isLoggedIn(authState.status)) {
      // Qurilma o'chirilganligini tekshirish
      if (_checkDeviceRemoved(context)) return;
      
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
      // Qurilma o'chirilganligini tekshirish
      if (_checkDeviceRemoved(context)) return;
      
      // Obunani yuklash
      context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
      
      // Bolalarni yuklash
      context.read<ChildBloc>().add(LoadChildrenEvent());
      
      // Bola sahifasiga o'tish
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChildHomePage()),
      );
    } else {
      // Token yo'q — avval ro'yxatdan o'tish kerak
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              const Text('Diqqat', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
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
