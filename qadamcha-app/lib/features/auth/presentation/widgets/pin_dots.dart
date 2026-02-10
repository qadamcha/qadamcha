import 'package:flutter/material.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';

class PinDots extends StatelessWidget {
  final int pinLength;
  final int currentLength;
  final String? errorMessage;

  const PinDots({
    super.key,
    this.pinLength = 4,
    required this.currentLength,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (index) {
            final isFilled = index < currentLength;
            final isError = errorMessage != null && errorMessage!.isNotEmpty;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled 
                    ? (isError ? AppColors.error : AppColors.primary) 
                    : Colors.transparent,
                border: Border.all(
                  color: isError 
                      ? AppColors.error 
                      : (isFilled ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3)),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ],
    );
  }
}
