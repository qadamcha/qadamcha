import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Back button box widget matching full_architecture.html design
/// 38x38 rounded box with chevron icon
class BackButtonBox extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const BackButtonBox({
    super.key,
    this.onPressed,
    this.size = 38,
    this.iconSize = 18,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Icon(
            Icons.chevron_left,
            size: iconSize,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
