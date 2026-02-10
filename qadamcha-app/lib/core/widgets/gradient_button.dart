import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Gradient button widget matching full_architecture.html design
/// Supports: Primary (blue), Gold (subscription), Error (red) variants
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GradientButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    GradientButtonType? type,
    GradientButtonType? variant,
    this.isLoading = false,
    this.icon,
    this.height = 54,
    this.borderRadius = 13,
  }) : type = type ?? variant ?? GradientButtonType.primary;


  LinearGradient get _gradient {
    switch (type) {
      case GradientButtonType.primary:
        return AppColors.primaryGradient;
      case GradientButtonType.gold:
        return AppColors.goldGradient;
      case GradientButtonType.error:
        return AppColors.errorGradient;
    }
  }

  List<BoxShadow> get _shadows {
    switch (type) {
      case GradientButtonType.primary:
        return [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
      case GradientButtonType.gold:
        return [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
      case GradientButtonType.error:
        return [
          BoxShadow(
            color: AppColors.error.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: onPressed != null ? _gradient : null,
          color: onPressed == null ? AppColors.textDisabled : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onPressed != null ? _shadows : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

enum GradientButtonType {
  primary,
  gold,
  error,
}

/// Alias for backward compatibility
typedef GradientButtonVariant = GradientButtonType;
