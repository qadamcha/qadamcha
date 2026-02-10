import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom number keypad widget matching full_architecture.html design
/// 3x4 grid with numbers 1-9, 0, and backspace
class CustomKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final double buttonHeight;
  final double spacing;

  const CustomKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.buttonHeight = 60,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        SizedBox(height: spacing),
        _buildRow(['4', '5', '6']),
        SizedBox(height: spacing),
        _buildRow(['7', '8', '9']),
        SizedBox(height: spacing),
        _buildRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return _buildEmptyKey();
        } else if (key == 'backspace') {
          return _buildBackspaceKey();
        } else {
          return _buildNumberKey(key);
        }
      }).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: GestureDetector(
        onTap: () => onKeyPressed(number),
        child: Container(
          width: buttonHeight * 1.4,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: GestureDetector(
        onTap: onBackspace,
        child: Container(
          width: buttonHeight * 1.4,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              '⌫',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyKey() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: SizedBox(
        width: buttonHeight * 1.4,
        height: buttonHeight,
      ),
    );
  }
}
