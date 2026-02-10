import 'package:flutter/material.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';

class PinKeypad extends StatelessWidget {
  final Function(String) onDigitEntered;
  final VoidCallback onBackspace;
  final bool isLoading;

  const PinKeypad({
    super.key,
    required this.onDigitEntered,
    required this.onBackspace,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 24),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 24),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 24),
        _buildRow([null, '0', 'backspace']),
      ],
    );
  }

  Widget _buildRow(List<dynamic> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        if (item == null) {
          return const SizedBox(width: 80, height: 80);
        }
        if (item == 'backspace') {
          return _buildBackspaceButton();
        }
        return _buildDigitButton(item as String);
      }).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : () => onDigitEntered(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : onBackspace,
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
