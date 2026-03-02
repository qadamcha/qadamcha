import 'package:flutter/material.dart';

/// Bolalar sahifasi uchun toza, iliq gradient fon
/// Animatsiyasiz, ko'zga yoqimli, professional
class KidsBackground extends StatelessWidget {
  final Widget child;
  final Color topColor;
  final Color bottomColor;

  const KidsBackground({
    super.key,
    required this.child,
    this.topColor = const Color(0xFFFFF5F0), // Warm peach
    this.bottomColor = const Color(0xFFFFFBFA), // Almost white
  });

  /// Multfilmlar uchun (iliq peach)
  const KidsBackground.cartoons({
    super.key,
    required this.child,
  })  : topColor = const Color(0xFFFFF5F0),
        bottomColor = const Color(0xFFFFFBFA);

  /// O'yinlar uchun (iliq mint)
  const KidsBackground.games({
    super.key,
    required this.child,
  })  : topColor = const Color(0xFFF0FFF5),
        bottomColor = const Color(0xFFFAFFFD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: child,
    );
  }
}
