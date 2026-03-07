import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// G'alaba oynasi — smooth konfetti animatsiyasi bilan
class CelebrationDialog extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onClear;
  final VoidCallback onExit;

  const CelebrationDialog({
    super.key,
    required this.onSave,
    required this.onClear,
    required this.onExit,
  });

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  final List<_ConfettiParticle> _confetti = [];

  @override
  void initState() {
    super.initState();

    // Dialog scale animatsiyasi
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim =
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _scaleController.forward();

    // Konfetti animatsiya controller — cheksiz davom etadi
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 40 ta konfetti zarrachasi generatsiya qilish
    final random = Random();
    final colors = [
      const Color(0xFFFF6B9D),
      const Color(0xFFFFA726),
      const Color(0xFF7C3AED),
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFFFFEE58),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];

    for (int i = 0; i < 40; i++) {
      _confetti.add(_ConfettiParticle(
        x: random.nextDouble(),
        startY: -random.nextDouble() * 0.5, // Yuqoridan boshlanadi
        speed: 0.3 + random.nextDouble() * 0.7, // Har xil tezlik
        size: 4 + random.nextDouble() * 8,
        color: colors[random.nextInt(colors.length)],
        swingAmplitude: 0.02 + random.nextDouble() * 0.06, // Chayqalish
        swingSpeed: 1 + random.nextDouble() * 3, // Chayqalish tezligi
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: 1 + random.nextDouble() * 4,
        shape: random.nextInt(3), // 0=doira, 1=to'rtburchak, 2=yulduz
        delay: random.nextDouble(), // Kechikish — barcha birdan chiqmaydi
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFEF3C7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: const Color(0xFFFFA726),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ═══ ANIMATED CONFETTI ═══
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ConfettiPainter(
                          particles: _confetti,
                          progress: _confettiController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ═══ MAIN CONTENT ═══
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stars and trophy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBouncingStar(0),
                      SizedBox(width: 8.w),
                      Text('🏆', style: TextStyle(fontSize: 56.sp)),
                      SizedBox(width: 8.w),
                      _buildBouncingStar(1),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFF6B9D),
                        Color(0xFFFFA726),
                        Color(0xFF7C3AED),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'BARAKALLA!',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    'Rasmni ajoyib bo\'yading! 🌟',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  // Save button — big and prominent
                  _build3DButton(
                    label: 'Saqlash va chiqish',
                    icon: Icons.download_rounded,
                    gradient: const [Color(0xFF22C55E), Color(0xFF4ADE80)],
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSave();
                    },
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Expanded(
                        child: _build3DButton(
                          label: 'Qayta',
                          icon: Icons.refresh_rounded,
                          gradient: const [
                            Color(0xFFF97316),
                            Color(0xFFFBBF24),
                          ],
                          onTap: () {
                            Navigator.pop(context);
                            widget.onClear();
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _build3DButton(
                          label: 'Boshqasi',
                          icon: Icons.grid_view_rounded,
                          gradient: const [
                            Color(0xFF3B82F6),
                            Color(0xFF93C5FD),
                          ],
                          onTap: () {
                            Navigator.pop(context);
                            widget.onExit();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingStar(int index) {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final bounce =
            sin((_confettiController.value * 2 * pi * 2) + index * pi) * 4;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: child,
        );
      },
      child: Text('⭐', style: TextStyle(fontSize: 28.sp)),
    );
  }

  Widget _build3DButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Konfetti zarrachasi — tushish, chayqalish, aylanish parametrlari
class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double swingAmplitude;
  final double swingSpeed;
  final double rotation;
  final double rotationSpeed;
  final int shape; // 0=doira, 1=to'rtburchak, 2=yulduz
  final double delay;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.swingAmplitude,
    required this.swingSpeed,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
    required this.delay,
  });
}

/// Custom painter — GPU da ishlaydi, 60fps smooth
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Kechikish bilan hisoblash
      final adjustedProgress = (progress + p.delay) % 1.0;

      // Y pozitsiya: yuqoridan pastga tushish
      final y = (p.startY + adjustedProgress * (1.0 + p.speed)) % 1.3 - 0.15;

      // X pozitsiya: chapga-o'ngga chayqalish (sin wave)
      final swingX =
          sin(adjustedProgress * 2 * pi * p.swingSpeed) * p.swingAmplitude;
      final x = p.x + swingX;

      // Ekran koordinatalariga o'girish
      final px = x * size.width;
      final py = y * size.height;

      // Aylanish
      final angle = p.rotation + adjustedProgress * 2 * pi * p.rotationSpeed;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      switch (p.shape) {
        case 0: // Doira
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 1: // To'rtburchak
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
              const Radius.circular(1.5),
            ),
            paint,
          );
          break;
        case 2: // Uchburchak/yulduz
          final path = Path();
          final s = p.size / 2;
          path.moveTo(0, -s);
          path.lineTo(s * 0.5, s * 0.3);
          path.lineTo(-s * 0.5, s * 0.3);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
