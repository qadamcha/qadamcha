import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';

/// New PIN Page — PIN tiklash oqimi uchun
/// OTP tasdiqlangandan keyin yangi 4 raqamli PIN kiritish
class NewPinPage extends StatefulWidget {
  final String phone;

  const NewPinPage({super.key, required this.phone});

  @override
  State<NewPinPage> createState() => _NewPinPageState();
}

class _NewPinPageState extends State<NewPinPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  final int _pinLength = 4;

  void _onKeyPressed(String key) {
    if (_isConfirmStep) {
      if (_confirmPin.length < _pinLength) {
        setState(() => _confirmPin += key);
        if (_confirmPin.length == _pinLength) {
          _submitPin();
        }
      }
    } else {
      if (_pin.length < _pinLength) {
        setState(() => _pin += key);
        if (_pin.length == _pinLength) {
          setState(() => _isConfirmStep = true);
        }
      }
    }
  }

  void _onBackspace() {
    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        // Qaytib birinchi bosqichga
        setState(() {
          _isConfirmStep = false;
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    }
  }

  void _submitPin() {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PIN kodlar mos kelmadi. Qaytadan kiriting."),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirmStep = false;
      });
      return;
    }

    context.read<AuthBloc>().add(ResetPinEvent(
      phone: widget.phone,
      newPin: _pin,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.pinReset) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN kod muvaffaqiyatli yangilandi!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(phone: widget.phone),
            ),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Xatolik yuz berdi'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _pin = '';
            _confirmPin = '';
            _isConfirmStep = false;
          });
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 24),
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('\u{1F511}', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                Text(
                  _isConfirmStep ? 'PIN ni tasdiqlang' : 'Yangi PIN yarating',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isConfirmStep
                      ? 'Xavfsizlik uchun qayta kiriting'
                      : 'Xavfsiz 4 raqamli PIN tanlang',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 36),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final isFilled = index < currentPin.length;
                    return Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppColors.success : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? AppColors.success : AppColors.border,
                          width: 2.5,
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Keypad
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state.status == AuthStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
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
