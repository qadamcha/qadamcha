import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';
import 'role_selection_page.dart';

/// PIN Create Page — parent_pin_page dizayniga mos
/// Oq fon, circle emoji icon, PinDots + PinKeypad, 2 bosqichli (yaratish + tasdiqlash)
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
  String _error = '';
  bool _isConfirming = false;
  bool _isLoading = false;

  void _onDigitEntered(String digit) {
    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _error = '';
        });
        if (_confirmPin.length == 4) {
          _validateAndRegister();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _error = '';
        });
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
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
          _error = '';
        });
      } else {
        // Birinchi bosqichga qaytish
        setState(() {
          _isConfirming = false;
          _pin = '';
          _error = '';
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _error = '';
        });
      }
    }
  }

  void _validateAndRegister() {
    if (_pin == _confirmPin) {
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(RegisterEvent(
            phone: widget.phone,
            name: widget.name,
            pin: _pin,
            childName: widget.childName,
            childAge: widget.childAge,
            childGender: widget.childGender,
          ));
    } else {
      setState(() {
        _error = 'PIN kodlar mos kelmaydi. Qaytadan urinib ko\'ring.';
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.registered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Muvaffaqiyatli ro'yxatdan o'tdingiz!"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const RoleSelectionPage(),
            ),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _isLoading = false;
            _error = state.errorMessage ?? 'Xatolik yuz berdi';
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        if (_isConfirming) {
                          setState(() {
                            _isConfirming = false;
                            _confirmPin = '';
                            _pin = '';
                            _error = '';
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      color: AppColors.textPrimary,
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Icon — parent_pin_page uslubida
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _isConfirming ? '✅' : '🔐',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                _isConfirming ? 'PIN kodni tasdiqlang' : 'PIN kod yarating',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isConfirming
                    ? 'Xavfsizlik uchun yana bir marta kiriting'
                    : 'Tez va xavfsiz kirish uchun',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),

              const SizedBox(height: 32),

              // PIN Dots — PinDots widgeti
              PinDots(
                currentLength: currentPin.length,
                errorMessage: _error,
              ),

              const SizedBox(height: 16),

              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isConfirming ? '2/2 Tasdiqlash' : '1/2 PIN yaratish',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Keypad — PinKeypad widgeti
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
