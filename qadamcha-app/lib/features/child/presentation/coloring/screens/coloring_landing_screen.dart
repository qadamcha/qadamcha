import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../engine/sound_service.dart';
import 'coloring_browse_screen.dart';
import 'coloring_gallery_screen.dart';
import 'my_artworks_screen.dart';

// ═══════════════════════════════════════════════════════════
// LANDING PAGE — Doodle Background + Bold Game Buttons
// ═══════════════════════════════════════════════════════════
class ColoringLandingScreen extends StatefulWidget {
  const ColoringLandingScreen({super.key});

  @override
  State<ColoringLandingScreen> createState() => _ColoringLandingScreenState();
}

class _ColoringLandingScreenState extends State<ColoringLandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _introCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _sparkleCtrl;

  bool _introDone = false;

  // Animatsiya vaqtlari (normalizatsiyalangan 0-1, 5.5s umumiy):
  // 0.00-0.18 = 0-1s     : Rasmlarim pastdan
  // 0.18-0.36 = 1-2s     : O'yna chapdan
  // 0.36-0.45 = 2-2.5s   : Yangilar o'ngdan
  // 0.45-0.64 = 2.5-3.5s : Mascot tepadan
  // 0.64-0.80 = 3.5-4.5s : Rangli chapdan + Dunyo o'ngdan
  // 0.80-1.00 = 4.5-5.5s : Hammasi joylashib bo'ldi

  @override
  void initState() {
    super.initState();
    SoundService().init();
    SoundService().preloadIntro();

    _introCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5500),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _introDone = true);
    });

    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        SoundService().playIntro();
        _introCtrl.forward();
      }
    });
  }

  /// Smooth ease helper — [start..end] oralig'ida progress hisoblaydi
  double _ease(double start, double end, [Curve curve = Curves.easeOutCubic]) {
    final v = _introCtrl.value;
    if (v < start) return 0.0;
    if (v > end) return 1.0;
    return curve.transform(((v - start) / (end - start)).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    SoundService().stopIntro();
    _introCtrl.dispose();
    _floatCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introCtrl, _floatCtrl, _sparkleCtrl]),
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Orqa fon rasmi
              Positioned.fill(
                child: Image.asset(
                  'assets/images/landing_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Sparkle elementlar
              ..._buildSparkleDecos(size),
              // Main content
              SafeArea(child: _buildContent()),
            ],
          );
        },
      ),
    );
  }

  // ═══ SPARKLE DEKORLARI ═══
  List<Widget> _buildSparkleDecos(Size size) {
    final rng = Random(42);
    final sparkles = <Widget>[];
    final emojis = ['✨', '⭐', '🌟', '💫', '✨', '⭐', '🌟', '💫'];

    for (int i = 0; i < 8; i++) {
      final t = (_sparkleCtrl.value + i * 0.125) % 1.0;
      final opacity = (sin(t * pi) * 0.6).clamp(0.0, 1.0);
      final scale = 0.7 + sin(t * pi) * 0.4;
      // Faqat mascot atrofida
      final angle = (i / 8) * 2 * pi + _sparkleCtrl.value * pi * 0.5;
      final radius = 130.w + rng.nextDouble() * 50;
      final cx = size.width / 2 + cos(angle) * radius;
      final cy = size.height * 0.38 + sin(angle) * radius * 0.7;

      sparkles.add(Positioned(
        left: cx - 10, top: cy - 10,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Text(emojis[i], style: TextStyle(fontSize: 14.sp)),
          ),
        ),
      ));
    }
    return sparkles;
  }

  // ═══ MAIN CONTENT ═══
  Widget _buildContent() {
    return Column(
      children: [
        SizedBox(height: 6.h),
        // Title — 5-bosqich: chapdan Rangli + o'ngdan Dunyo
        _buildTitle(),
        // Mascot — 4-bosqich: tepadan tushadi
        Expanded(
          child: _buildMascot(),
        ),
        // Game Buttons — alohida animatsiyalar
        _buildGameButtons(),
        SizedBox(height: 14.h),
      ],
    );
  }

  // ═══ TITLE — 5-bosqich: Rangli chapdan, Dunyo o'ngdan ═══
  Widget _buildTitle() {
    // Rangli chapdan (0.73-0.88)
    final rangliP = _ease(0.64, 0.80, Curves.easeOutBack);
    // Dunyo o'ngdan (0.64-0.80)
    final dunyoP = _ease(0.64, 0.80, Curves.easeOutBack);

    return SizedBox(
      width: 1.sw,
      height: 190.h,
      child: Stack(
        children: [
          // Rangli — chapdan kiradi
          Opacity(
            opacity: rangliP.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-1.sw * (1 - rangliP), 0),
              child: SizedBox(
                width: 1.sw,
                height: 95.h,
                child: CustomPaint(
                  painter: _ArcTitlePainter(line: 1),
                ),
              ),
            ),
          ),
          // Dunyo — o'ngdan kiradi
          Positioned(
            top: 95.h,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: dunyoP.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(1.sw * (1 - dunyoP), 0),
                child: SizedBox(
                  width: 1.sw,
                  height: 95.h,
                  child: CustomPaint(
                    painter: _ArcTitlePainter(line: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ MASCOT — 4-bosqich: o'ngdan tangadek aylanib kiradi ═══
  Widget _buildMascot() {
    // 4-bosqich: 0.45-0.64
    final spinP = _ease(0.45, 0.64, Curves.easeOutCubic);
    final mascotReady = spinP >= 1.0;
    final floatY = mascotReady ? sin(_floatCtrl.value * pi) * 8 : 0.0;
    final tilt = mascotReady ? sin(_floatCtrl.value * pi * 1.3) * 0.008 : 0.0;

    // Tanga aylanishi — 2 marta to'liq aylana (4π)
    final coinSpin = (1 - spinP) * pi * 4;
    // O'ngdan chapga gorizontal harakat
    final slideX = (1 - spinP) * 1.sw;

    return Center(
      child: Opacity(
        opacity: spinP.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(slideX, floatY - 45.h),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003) // 3D perspektiv
              ..rotateY(coinSpin), // Tanga effekti
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: (0.3 + spinP * 0.7).clamp(0.0, 1.0),
                child: Image.asset(
                  'assets/images/paint_mascot.png',
                  width: 1.sw,
                  height: 1.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══ GAME BUTTONS — staggered animatsiya ═══
  Widget _buildGameButtons() {
    // 1-bosqich Rasmlarim: pastdan (0.00-0.18)
    final rasmlarimP = _ease(0.00, 0.18, Curves.easeOutBack);
    // 2-bosqich O'yna: chapdan (0.18-0.36)
    final oynaP = _ease(0.18, 0.36, Curves.easeOutBack);
    // 3-bosqich Yangilar: o'ngdan (0.36-0.45)
    final yangilarP = _ease(0.36, 0.45, Curves.easeOutBack);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // 1-qator: O'yna + Yangilar
          SizedBox(
            height: 62.h,
            child: Row(
              children: [
                // O'YNA — chapdan kiradi (2-bosqich)
                Expanded(
                  flex: 5,
                  child: Opacity(
                    opacity: oynaP.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(-1.sw * (1 - oynaP), 0),
                      child: _capsuleButton(
                        label: "O'yna",
                        icon: '',
                        iconRight: true,
                        bgColors: [const Color(0xFF9AE84E), const Color(0xFF6BC72F)],
                        bottomColor: const Color(0xFF3E8C1E),
                        fontSize: 26.sp,
                        iconSize: 22.sp,
                        onTap: () => _navigate(const ColoringBrowseScreen()),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // YANGILAR — o'ngdan kiradi (3-bosqich)
                Expanded(
                  flex: 4,
                  child: Opacity(
                    opacity: yangilarP.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(1.sw * (1 - yangilarP), 0),
                      child: _capsuleButton(
                        label: 'Yangilar',
                        icon: '',
                        iconRight: false,
                        bgColors: [const Color(0xFFFFBB5C), const Color(0xFFF59E20)],
                        bottomColor: const Color(0xFFCC7A10),
                        fontSize: 19.sp,
                        iconSize: 16.sp,
                        onTap: () => _navigate(const ColoringGalleryScreen()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // 2-qator: Rasmlarim — pastdan kiradi (1-bosqich)
          SizedBox(
            height: 56.h,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              child: Opacity(
                opacity: rasmlarimP.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 150.h * (1 - rasmlarimP)),
                  child: _capsuleButton(
                    label: 'Rasmlarim',
                    icon: '',
                    iconRight: true,
                    bgColors: [const Color(0xFFC289E8), const Color(0xFF9B5CC5)],
                    bottomColor: const Color(0xFF6D3A96),
                    fontSize: 20.sp,
                    iconSize: 18.sp,
                    onTap: () => _navigate(const MyArtworksScreen()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capsule-shakldagi o'yin tugmasi — skrinshot 1:1
  Widget _capsuleButton({
    required String label,
    required String icon,
    required bool iconRight,
    required List<Color> bgColors,
    required Color bottomColor,
    required VoidCallback onTap,
    required double fontSize,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        SoundService().playPop();
        onTap();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          return Container(
            decoration: BoxDecoration(
              // Pastki 3D soya — to'q rang
              color: bottomColor,
              borderRadius: BorderRadius.circular(h / 2),
            ),
            padding: EdgeInsets.only(bottom: 4.h),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bgColors,
                ),
                borderRadius: BorderRadius.circular(h / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 3.5,
                ),
              ),
              child: Stack(
                children: [
                  // Tepada yorqin shimmer highlight
                  Positioned(
                    top: 4.h,
                    left: h * 0.3,
                    right: h * 0.3,
                    child: Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  // Matn + icon
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!iconRight)
                          Text(icon, style: TextStyle(
                            fontSize: iconSize,
                            color: Colors.white,
                          )),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (iconRight)
                          Text(icon, style: TextStyle(
                            fontSize: iconSize,
                            color: Colors.white,
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigate(Widget page) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.93, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// DOODLE PAINTER — ochiq kulrang chiziqlar orqa fonda
// ═══════════════════════════════════════════════════════════
class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final rng = Random(123);
    final w = size.width;
    final h = size.height;

    // Yulduzchalar — ko'proq va kattaroq
    _drawStar(canvas, Offset(w * 0.10, h * 0.06), 14, paint);
    _drawStar(canvas, Offset(w * 0.88, h * 0.10), 12, paint);
    _drawStar(canvas, Offset(w * 0.06, h * 0.48), 10, paint);
    _drawStar(canvas, Offset(w * 0.92, h * 0.42), 13, paint);
    _drawStar(canvas, Offset(w * 0.50, h * 0.04), 11, paint);
    _drawStar(canvas, Offset(w * 0.20, h * 0.30), 8, paint);
    _drawStar(canvas, Offset(w * 0.80, h * 0.55), 9, paint);
    _drawStar(canvas, Offset(w * 0.35, h * 0.68), 7, paint);

    // Yurakchalar
    _drawHeart(canvas, Offset(w * 0.85, h * 0.06), 12, paint);
    _drawHeart(canvas, Offset(w * 0.06, h * 0.22), 10, paint);
    _drawHeart(canvas, Offset(w * 0.93, h * 0.58), 11, paint);
    _drawHeart(canvas, Offset(w * 0.70, h * 0.03), 8, paint);

    // Mushukcha yuzlar
    _drawCat(canvas, Offset(w * 0.90, h * 0.18), 16, paint);
    _drawCat(canvas, Offset(w * 0.08, h * 0.65), 14, paint);

    // Nota belgilari
    _drawNote(canvas, Offset(w * 0.04, h * 0.12), 12, paint);
    _drawNote(canvas, Offset(w * 0.96, h * 0.32), 10, paint);

    // Kichik doiralar — ko'proq
    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      canvas.drawCircle(Offset(x, y), 1.5 + rng.nextDouble() * 3, paint);
    }

    // Bo'yoq tomchilari
    _drawDrop(canvas, Offset(w * 0.15, h * 0.38), 10, paint);
    _drawDrop(canvas, Offset(w * 0.87, h * 0.48), 8, paint);
    _drawDrop(canvas, Offset(w * 0.06, h * 0.82), 9, paint);
    _drawDrop(canvas, Offset(w * 0.75, h * 0.70), 7, paint);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final ox = c.dx + cos(outerAngle) * r;
      final oy = c.dy + sin(outerAngle) * r;
      final ix = c.dx + cos(innerAngle) * r * 0.4;
      final iy = c.dy + sin(innerAngle) * r * 0.4;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Paint paint) {
    final path = Path();
    path.moveTo(c.dx, c.dy + s * 0.35);
    path.cubicTo(c.dx - s, c.dy - s * 0.5, c.dx - s * 0.3, c.dy - s, c.dx, c.dy - s * 0.4);
    path.cubicTo(c.dx + s * 0.3, c.dy - s, c.dx + s, c.dy - s * 0.5, c.dx, c.dy + s * 0.35);
    canvas.drawPath(path, paint);
  }

  void _drawCat(Canvas canvas, Offset c, double s, Paint paint) {
    // Yuz
    canvas.drawCircle(c, s, paint);
    // Quloqlar
    final path = Path();
    path.moveTo(c.dx - s * 0.7, c.dy - s * 0.5);
    path.lineTo(c.dx - s * 0.4, c.dy - s * 1.2);
    path.lineTo(c.dx - s * 0.1, c.dy - s * 0.6);
    canvas.drawPath(path, paint);
    final path2 = Path();
    path2.moveTo(c.dx + s * 0.7, c.dy - s * 0.5);
    path2.lineTo(c.dx + s * 0.4, c.dy - s * 1.2);
    path2.lineTo(c.dx + s * 0.1, c.dy - s * 0.6);
    canvas.drawPath(path2, paint);
    // Ko'zlar
    final fill = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(c.dx - s * 0.35, c.dy - s * 0.15), s * 0.12, fill);
    canvas.drawCircle(Offset(c.dx + s * 0.35, c.dy - s * 0.15), s * 0.12, fill);
    // Og'iz
    final smile = Path();
    smile.moveTo(c.dx - s * 0.15, c.dy + s * 0.2);
    smile.quadraticBezierTo(c.dx, c.dy + s * 0.4, c.dx + s * 0.15, c.dy + s * 0.2);
    canvas.drawPath(smile, paint);
  }

  void _drawNote(Canvas canvas, Offset c, double s, Paint paint) {
    // Nota boshi
    canvas.drawOval(Rect.fromCenter(center: c, width: s, height: s * 0.7), paint);
    // Poya
    canvas.drawLine(Offset(c.dx + s * 0.4, c.dy), Offset(c.dx + s * 0.4, c.dy - s * 1.5), paint);
    // Bayroqcha
    final flag = Path();
    flag.moveTo(c.dx + s * 0.4, c.dy - s * 1.5);
    flag.quadraticBezierTo(c.dx + s * 1.2, c.dy - s * 1.2, c.dx + s * 0.4, c.dy - s * 0.8);
    canvas.drawPath(flag, paint);
  }

  void _drawDrop(Canvas canvas, Offset c, double s, Paint paint) {
    final path = Path();
    path.moveTo(c.dx, c.dy - s);
    path.quadraticBezierTo(c.dx + s * 0.8, c.dy + s * 0.3, c.dx, c.dy + s * 0.6);
    path.quadraticBezierTo(c.dx - s * 0.8, c.dy + s * 0.3, c.dx, c.dy - s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) => false;
}
// ═══════════════════════════════════════════════════════════
// ARC TITLE PAINTER — haqiqiy doira yoyi (circular arc)
// ═══════════════════════════════════════════════════════════
class _ArcTitlePainter extends CustomPainter {
  final int line; // 0=ikkalasi, 1=faqat Rangli, 2=faqat Dunyo
  _ArcTitlePainter({this.line = 0});

  // 1-qator
  static const _line1 = 'Rangli';
  static const _colors1 = [
    Color(0xFFFF5A5F), // R
    Color(0xFFFF9F43), // a
    Color(0xFFFECA57), // n
    Color(0xFF2ED573), // g
    Color(0xFF45AAF2), // l
    Color(0xFFA55EEA), // i
  ];

  // 2-qator
  static const _line2 = 'Dunyo';
  static const _colors2 = [
    Color(0xFF45AAF2), // D
    Color(0xFF2ED573), // u
    Color(0xFFFECA57), // n
    Color(0xFFFF9F43), // y
    Color(0xFFFF5A5F), // o
  ];

  static const _outlineColor = Color(0xFF3D3270);

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = size.width * 0.21;
    final outlineWidth = fontSize * 0.09;
    final cx = size.width / 2;
    final R = size.width * 0.85;

    if (line == 0 || line == 1) {
      // "Rangli" — bitta SizedBox ichida, markazda
      final cyR = (line == 1) ? size.height * 0.50 + R : size.height * 0.30 + R;
      _drawCircularArc(
        canvas,
        word: _line1, colors: _colors1,
        cx: cx, cy: cyR, R: R,
        fontSize: fontSize, outlineWidth: outlineWidth,
      );
    }

    if (line == 0 || line == 2) {
      // "Dunyo" — bitta SizedBox ichida, markazda
      final cyD = (line == 2) ? size.height * 0.50 + R : size.height * 0.74 + R;
      _drawCircularArc(
        canvas,
        word: _line2, colors: _colors2,
        cx: cx, cy: cyD, R: R,
        fontSize: fontSize, outlineWidth: outlineWidth,
      );
    }
  }

  /// Haqiqiy doira yoyi bo'ylab so'zni chizish
  /// cx, cy — doira markazi
  /// R — doira radiusi
  /// Har bir harf doira bo'ylab θ burchakda joylashadi:
  ///   x = cx + R * sin(θ)
  ///   y = cy - R * cos(θ)
  /// Harf θ burchakka moslashtiriladi (tangent yo'nalishi)
  void _drawCircularArc(
    Canvas canvas, {
    required String word,
    required List<Color> colors,
    required double cx,
    required double cy,
    required double R,
    required double fontSize,
    required double outlineWidth,
  }) {
    // 1. Har bir harfni o'lchab, ularning kengliklari ro'yxatini olish
    final widths = <double>[];
    final tps = <TextPainter>[];
    for (int i = 0; i < word.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: word[i],
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tps.add(tp);
      widths.add(tp.width);
    }

    // 2. Umumiy matn kengligi
    double totalWidth = 0;
    for (final w in widths) {
      totalWidth += w;
    }

    // 3. Har bir harfning burchagini hisoblash
    //    Harf kengligi -> doira yoyi uzunligi -> burchak
    //    arcLength = R * angle  ->  angle = arcLength / R
    final totalAngle = totalWidth / R; // umumiy yoy burchagi (radianda)
    final startAngle = -totalAngle / 2; // chapdan boshlash

    // 4. Har bir harfni doira yoyi bo'ylab joylashtirish
    double currentAngle = startAngle;

    for (int i = 0; i < word.length; i++) {
      final tp = tps[i];
      final letterAngle = widths[i] / R; // bu harfning burchak uzunligi
      final theta = currentAngle + letterAngle / 2; // harfning markaz burchagi

      // Doiradagi pozitsiya:
      //   x = cx + R * sin(theta)
      //   y = cy - R * cos(theta)
      final x = cx + R * sin(theta);
      final y = cy - R * cos(theta);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(theta); // harfni yoyga mos burib qo'yish

      final color = colors[i % colors.length];

      // ══ OUTLINE (stroke) ══
      final outlineTp = TextPainter(
        text: TextSpan(
          text: word[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = _outlineColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      outlineTp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      // ══ FILL (rangli) ══
      final fillTp = TextPainter(
        text: TextSpan(
          text: word[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      fillTp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();

      // Keyingi harfga o'tish
      currentAngle += letterAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcTitlePainter old) => old.line != line;
}
