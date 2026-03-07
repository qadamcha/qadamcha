
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../engine/sound_service.dart';

/// Ranglar Palitrasi — Katta 3D Qalamchalar
class ColoringPaletteWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const ColoringPaletteWidget({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        // Yog'och qalamcha qutisi
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5EDE0),
            Color(0xFFE8DDD0),
            Color(0xFFDDD2C4),
            Color(0xFFE8DDD0),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFC4B5A2),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0xFFF5EDE0),
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ColoringPalette.colors.length, (index) {
              final color = ColoringPalette.colors[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundService().playPop();
                  onColorSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                  // Tanlanganda katta bo'ladi va yuqoriga chiqadi
                  transform: Matrix4.translationValues(
                    0,
                    isSelected ? -14.h : 0,
                    0,
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Qalamcha
                      CustomPaint(
                        size: Size(
                          isSelected ? 38.w : 32.w,
                          isSelected ? 100.h : 90.h,
                        ),
                        painter: _CrayonPainter(
                          color: color,
                          isSelected: isSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Premium 3D Qalamcha — CustomPainter
class _CrayonPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  _CrayonPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tipHeight = h * 0.22;
    final bodyTop = tipHeight;
    final bodyHeight = h - tipHeight;
    final isWhite = color.computeLuminance() > 0.85;

    // Rang variantlari
    final lightColor = Color.lerp(color, Colors.white, 0.45)!;
    final midLightColor = Color.lerp(color, Colors.white, 0.2)!;
    final darkColor = Color.lerp(color, Colors.black, 0.3)!;
    final midDarkColor = Color.lerp(color, Colors.black, 0.12)!;

    // ═══════════════════════════════════════
    // QALAMCHA TANASI (body) — kuchli 3D
    // ═══════════════════════════════════════
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, bodyTop, w, bodyHeight),
      const Radius.circular(4),
    );

    // 5 zonali gradient — real 3D silindr effekti
    final bodyGradient = LinearGradient(
      colors: [
        midDarkColor,    // chap cheti — soya
        lightColor,       // chap — yorug' reflex
        midLightColor,    // o'rta-chap — asosiy yaltiroq
        color,            // o'rta — real rang
        midDarkColor,     // o'ng — soya boshlanadi
        darkColor,        // o'ng cheti — chuqur soya
      ],
      stops: const [0.0, 0.12, 0.28, 0.55, 0.82, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromLTWH(0, bodyTop, w, bodyHeight),
      );

    canvas.drawRRect(bodyRect, bodyPaint);

    // ── Vertikal yaltiroq chiziq (highlight) ──
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isWhite ? 0.2 : 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(w * 0.18, bodyTop, w * 0.18, bodyHeight));

    canvas.drawRect(
      Rect.fromLTWH(w * 0.18, bodyTop + 1, w * 0.18, bodyHeight - 2),
      highlightPaint,
    );

    // ── O'ng chekkada qorong'i soya ──
    final edgeShadowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.15),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(w * 0.82, bodyTop, w * 0.18, bodyHeight));

    canvas.drawRect(
      Rect.fromLTWH(w * 0.82, bodyTop + 1, w * 0.18, bodyHeight - 2),
      edgeShadowPaint,
    );

    // ═══════════════════════════════════════
    // QALAMCHA UCHI (tip) — uchburchak 3D
    // ═══════════════════════════════════════
    // Chap yarmi — yorug'roq
    final tipLeftPath = Path();
    tipLeftPath.moveTo(w / 2, 0);
    tipLeftPath.lineTo(0, tipHeight);
    tipLeftPath.lineTo(w / 2, tipHeight);
    tipLeftPath.close();

    final tipLeftPaint = Paint()
      ..shader = LinearGradient(
        colors: [midLightColor, color],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w / 2, tipHeight));

    canvas.drawPath(tipLeftPath, tipLeftPaint);

    // O'ng yarmi — qorong'iroq
    final tipRightPath = Path();
    tipRightPath.moveTo(w / 2, 0);
    tipRightPath.lineTo(w, tipHeight);
    tipRightPath.lineTo(w / 2, tipHeight);
    tipRightPath.close();

    final tipRightPaint = Paint()
      ..shader = LinearGradient(
        colors: [midDarkColor, darkColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(w / 2, 0, w / 2, tipHeight));

    canvas.drawPath(tipRightPath, tipRightPaint);

    // Uch va tana orasidagi chiziq
    final dividePaint = Paint()
      ..color = darkColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, tipHeight), Offset(w, tipHeight), dividePaint);

    // ═══════════════════════════════════════
    // ETIKETKA — qalamchaning o'rtasida
    // ═══════════════════════════════════════
    final labelY = bodyTop + bodyHeight * 0.4;
    final labelH = bodyHeight * 0.2;

    // Oq etiketka fon
    final labelPaint = Paint()
      ..color = Colors.white.withValues(alpha: isWhite ? 0.1 : 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, labelY),
          width: w * 0.75,
          height: labelH,
        ),
        const Radius.circular(3),
      ),
      labelPaint,
    );

    // Etiketka border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, labelY),
          width: w * 0.75,
          height: labelH,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = darkColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // ═══════════════════════════════════════
    // PASTKI BURCHAK — dumaloq
    // ═══════════════════════════════════════
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h - 5, w, 5),
        const Radius.circular(3),
      ),
      Paint()..color = darkColor.withValues(alpha: 0.25),
    );

    // ═══════════════════════════════════════
    // OQ RANG BORDER
    // ═══════════════════════════════════════
    if (isWhite) {
      final strokePaint = Paint()
        ..color = const Color(0xFFBBBBBB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(bodyRect, strokePaint);

      final tipAll = Path();
      tipAll.moveTo(w / 2, 0);
      tipAll.lineTo(0, tipHeight);
      tipAll.lineTo(w, tipHeight);
      tipAll.close();
      canvas.drawPath(tipAll, strokePaint);
    }

    // ═══════════════════════════════════════
    // TANLANGAN EFFEKT — kuchli glow
    // ═══════════════════════════════════════
    if (isSelected) {
      // Tashqi glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-3, bodyTop - 3, w + 6, bodyHeight + 6),
          const Radius.circular(6),
        ),
        glowPaint,
      );

      // Oq chegaraviy border
      final selBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-1, bodyTop - 1, w + 2, bodyHeight + 2),
          const Radius.circular(5),
        ),
        selBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrayonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isSelected != isSelected;
}
