import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/custom_keypad.dart';

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
    // TODO: Implement code verification
    // Navigate to device success page on success
  }

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
              const SizedBox(height: 24),
              // Icon
              const Text('🔢', style: TextStyle(fontSize: 48)),
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
              Row(
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
                      const TextSpan(text: '📱 Ota-onangiz telefonida: '),
                      TextSpan(
                        text: 'Sozlamalar → Qurilma ulash',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' — u yerda kod bor'),
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
    );
  }
}
