import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../bloc/device_bloc.dart';

/// Family Code Input Page - matching full_architecture.html design
/// 6-digit code input with custom keypad
class FamilyCodeInputPage extends StatefulWidget {
  const FamilyCodeInputPage({super.key});

  @override
  State<FamilyCodeInputPage> createState() => _FamilyCodeInputPageState();
}

class _FamilyCodeInputPageState extends State<FamilyCodeInputPage> {
  String _code = '';
  final int _codeLength = 6;

  void _onKeyPressed(String key) {
    if (_code.length < _codeLength) {
      setState(() {
        _code += key;
      });
      if (_code.length == _codeLength) {
        _verifyCode();
      }
    }
  }

  void _onBackspace() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
      });
    }
  }

  void _verifyCode() {
    context.read<DeviceBloc>().add(ValidateCodeEvent(_code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceBloc, DeviceState>(
      listenWhen: (previous, current) =>
          current.isValidatingCode != previous.isValidatingCode ||
          current.isCodeValid != previous.isCodeValid,
      listener: (context, state) {
        if (state.isCodeValid == true) {
          // Muvaffaqiyat — qurilma ulandi
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Muvaffaqiyat!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
              content: const Text(
                'Qurilma muvaffaqiyatli ulandi!',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog yopish
                    Navigator.of(context).pop(); // Sahifaga qaytish
                  },
                  child: const Text(
                    'Davom etish',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state.isCodeValid == false && !state.isValidatingCode) {
          // Xatolik
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Kod noto'g'ri yoki muddati tugagan"),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _code = '';
          });
        }
      },
      child: Scaffold(
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
                const SizedBox(height: 24),
                // Icon
                const Text('\u{1F522}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                // Title
                const Text(
                  'Oila kodini kiriting',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Ota-onangizdan 6 raqamli kodni so'rang",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 32),
                // Code input boxes
                BlocBuilder<DeviceBloc, DeviceState>(
                  builder: (context, state) {
                    if (state.isValidatingCode) {
                      return const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_codeLength, (index) {
                        final isFilled = index < _code.length;
                        return Container(
                          width: 46,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? AppColors.purple.withOpacity(0.06)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFilled
                                  ? AppColors.purple
                                  : AppColors.border,
                              width: isFilled ? 2.5 : 2,
                            ),
                          ),
                          child: Center(
                            child: isFilled
                                ? Text(
                                    _code[index],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Nunito',
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Help text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.1),
                    ),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.purple,
                        height: 1.5,
                        fontFamily: 'Nunito',
                      ),
                      children: [
                        const TextSpan(text: '\u{1F4F1} Ota-onangiz telefonida: '),
                        TextSpan(
                          text: 'Sozlamalar \u2192 Qurilma ulash',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' \u2014 u yerda kod bor'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Custom keypad
                CustomKeypad(
                  onKeyPressed: _onKeyPressed,
                  onBackspace: _onBackspace,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
