import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';

/// PIN Create Page - matching full_architecture.html design
/// 🔐 icon, dot indicators, custom keypad, confirmation step
class PinCreatePage extends StatefulWidget {
  final String phone;
  final String name;
  final String childName;
  final int childAge;
  final String childGender;

  const PinCreatePage({
    super.key,
    required this.phone,
    required this.name,
    required this.childName,
    required this.childAge,
    required this.childGender,
  });

  @override
  State<PinCreatePage> createState() => _PinCreatePageState();
}

class _PinCreatePageState extends State<PinCreatePage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  final int _pinLength = 4;

  void _onKeyPressed(String key) {
    if (_isConfirming) {
      if (_confirmPin.length < _pinLength) {
        setState(() {
          _confirmPin += key;
        });
        if (_confirmPin.length == _pinLength) {
          _validateAndRegister();
        }
      }
    } else {
      if (_pin.length < _pinLength) {
        setState(() {
          _pin += key;
        });
        if (_pin.length == _pinLength) {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _isConfirming = true;
            });
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        });
      } else {
        // Go back to first step
        setState(() {
          _isConfirming = false;
          _pin = '';
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    }
  }

  void _validateAndRegister() {
    if (_pin == _confirmPin) {
      context.read<AuthBloc>().add(RegisterEvent(
            phone: widget.phone,
            name: widget.name,
            pin: _pin,
            childName: widget.childName,
            childAge: widget.childAge,
            childGender: widget.childGender,
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN kodlar mos kelmaydi. Qaytadan urinib ko\'ring.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.registered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Muvaffaqiyatli ro'yxatdan o'tdingiz!"),
              backgroundColor: AppColors.success,
            ),
          );
          // State ni tozalash — LoginPage error ko'rsatmasligi uchun
          context.read<AuthBloc>().add(ResetAuthEvent());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(phone: widget.phone),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Xatolik yuz berdi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButtonBox(
                    onPressed: () {
                      if (_isConfirming) {
                        setState(() {
                          _isConfirming = false;
                          _confirmPin = '';
                          _pin = '';
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Icon
                Container(
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
                    child: Text('🔐', style: TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                Text(
                  _isConfirming ? 'PIN kodni tasdiqlang' : 'PIN kod yarating',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isConfirming
                      ? 'Xavfsizlik uchun yana bir marta kiriting'
                      : 'Tez va xavfsiz kirish uchun',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 32),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final currentPin = _isConfirming ? _confirmPin : _pin;
                    final isFilled = index < currentPin.length;
                    return Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2.5,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isConfirming ? '2/2 Tasdiqlash' : '1/2 PIN yaratish',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                const Spacer(),
                // Keypad
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state.status == AuthStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return CustomKeypad(
                      onKeyPressed: _onKeyPressed,
                      onBackspace: _onBackspace,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
