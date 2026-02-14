import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';
import 'package:qadamcha_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:qadamcha_app/features/auth/presentation/widgets/pin_dots.dart';
import 'package:qadamcha_app/features/auth/presentation/widgets/pin_keypad.dart';
import 'package:qadamcha_app/features/auth/presentation/pages/pin_reset_page.dart';
import 'package:qadamcha_app/features/home/presentation/pages/main_navigation_page.dart';

class ParentPinPage extends StatefulWidget {
  const ParentPinPage({super.key});

  @override
  State<ParentPinPage> createState() => _ParentPinPageState();
}

class _ParentPinPageState extends State<ParentPinPage> {
  String _pin = '';
  String _error = '';
  bool _isLoading = false;

  void _onDigitEntered(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = ''; // Clear error on new input
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = '';
      });
    }
  }

  void _verifyPin() {
    setState(() {
      _isLoading = true;
    });
    context.read<AuthBloc>().add(AuthVerifyPinEvent(_pin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.pinVerified ||
          curr.status == AuthStatus.error ||
          curr.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        if (state.status == AuthStatus.pinVerified) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationPage()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.unauthenticated) {
          setState(() {
            _isLoading = false;
            _error = state.errorMessage ?? 'Sessiya tugadi. Qayta kiring.';
            _pin = '';
          });
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _isLoading = false;
            _error = state.errorMessage ?? 'PIN kod noto\'g\'ri';
            _pin = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Back Button & Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textPrimary,
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👋',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Title
              const Text(
                'Salom, Ota-ona!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'PIN kodingizni kiriting',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),

              const SizedBox(height: 32),

              // PIN Dots
              PinDots(
                currentLength: _pin.length,
                errorMessage: _error,
              ),

              const Spacer(flex: 2),

              // Forgot PIN
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PinResetPage()),
                  );
                },
                child: const Text(
                  'PIN kodni unutdingizmi?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: PinKeypad(
                  onDigitEntered: _onDigitEntered,
                  onBackspace: _onBackspace,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
