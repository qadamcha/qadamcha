import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/jigsaw_sound_service.dart';
import 'jigsaw_category_screen.dart';

// ─── Jigsaw quadrant clipper ────────────────────────────────────────────
class _JigsawQuadrantClipper extends CustomClipper<Path> {
  final int quadrant;
  final double tabR, cornerR;
  _JigsawQuadrantClipper(
      {required this.quadrant, required this.tabR, this.cornerR = 20});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final hw = w / 2, hh = h / 2;
    final r = tabR, cr = cornerR;
    final path = Path();
    switch (quadrant) {
      case 0:
        path.moveTo(0, cr);
        path.quadraticBezierTo(0, 0, cr, 0);
        path.lineTo(hw, 0);
        path.lineTo(hw, hh / 2 - r);
        path.arcToPoint(Offset(hw, hh / 2 + r),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(hw, hh);
        path.lineTo(hw / 2 + r, hh);
        path.arcToPoint(Offset(hw / 2 - r, hh),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(0, hh);
        path.close();
      case 1:
        path.moveTo(hw, 0);
        path.lineTo(w - cr, 0);
        path.quadraticBezierTo(w, 0, w, cr);
        path.lineTo(w, hh);
        path.lineTo(hw + hw / 2 + r, hh);
        path.arcToPoint(Offset(hw + hw / 2 - r, hh),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(hw, hh);
        path.lineTo(hw, hh / 2 + r);
        path.arcToPoint(Offset(hw, hh / 2 - r),
            radius: Radius.circular(r), clockwise: false);
        path.close();
      case 2:
        path.moveTo(0, hh);
        path.lineTo(hw / 2 - r, hh);
        path.arcToPoint(Offset(hw / 2 + r, hh),
            radius: Radius.circular(r), clockwise: false);
        path.lineTo(hw, hh);
        path.lineTo(hw, hh + hh / 2 - r);
        path.arcToPoint(Offset(hw, hh + hh / 2 + r),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(hw, h);
        path.lineTo(cr, h);
        path.quadraticBezierTo(0, h, 0, h - cr);
        path.close();
      case 3:
        path.moveTo(hw, hh);
        path.lineTo(hw + hw / 2 - r, hh);
        path.arcToPoint(Offset(hw + hw / 2 + r, hh),
            radius: Radius.circular(r), clockwise: false);
        path.lineTo(w, hh);
        path.lineTo(w, h - cr);
        path.quadraticBezierTo(w, h, w - cr, h);
        path.lineTo(hw, h);
        path.lineTo(hw, hh + hh / 2 + r);
        path.arcToPoint(Offset(hw, hh + hh / 2 - r),
            radius: Radius.circular(r), clockwise: false);
        path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _JigsawQuadrantClipper old) =>
      old.quadrant != quadrant || old.tabR != tabR;
}

// ─── Sparkle burst ──────────────────────────────────────────────────────
class _Sparkle {
  final Offset dir;
  final double speed;
  final Color color;
  final double size;
  _Sparkle(this.dir, this.speed, this.color, this.size);
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double t;
  final Offset center;
  _SparklePainter(this.sparkles, this.t, this.center);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    for (final s in sparkles) {
      final dist = s.speed * t * 150;
      final x = center.dx + s.dir.dx * dist;
      final y = center.dy + s.dir.dy * dist;
      final o = (1.0 - t).clamp(0.0, 1.0);
      final r = s.size * (1.0 - t * 0.4);
      if (o <= 0) continue;
      canvas.drawCircle(Offset(x, y), r,
          Paint()
            ..color = s.color.withValues(alpha: o * 0.9)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7));
      canvas.drawCircle(Offset(x, y), r * 0.35,
          Paint()..color = Colors.white.withValues(alpha: o * 0.7));
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => true;
}

// ─── Floating background dots (Glowing circles & stars) ───────────────────
class _BgDot {
  Offset pos;
  double radius, phase;
  Color color;
  bool isStar;
  bool isPuzzlePiece;
  _BgDot(this.pos, this.radius, this.phase, this.color, {this.isStar = false, this.isPuzzlePiece = false});
}

class _BgDotPainter extends CustomPainter {
  final List<_BgDot> dots;
  final double tick;
  _BgDotPainter(this.dots, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final a = 0.3 + 0.2 * sin(tick * 3 + d.phase).abs();
      
      if (d.isPuzzlePiece) {
        canvas.save();
        canvas.translate(d.pos.dx, d.pos.dy);
        canvas.rotate(d.phase);
        final s = d.radius;
        final path = Path();
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          Radius.circular(s * 0.15),
        ));
        path.addOval(Rect.fromCenter(
          center: Offset(0, -s * 0.5),
          width: s * 0.4, height: s * 0.4,
        ));
        path.addOval(Rect.fromCenter(
          center: Offset(s * 0.5, 0),
          width: s * 0.4, height: s * 0.4,
        ));
        canvas.drawPath(path, Paint()
          ..color = d.color.withValues(alpha: a * 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.15));
        canvas.restore();
      } else if (d.isStar) {
        final path = Path();
        final center = d.pos;
        final r1 = d.radius;
        final r2 = d.radius * 0.25;
        for (int i = 0; i < 8; i++) {
          final r = i.isEven ? r1 : r2;
          final angle = i * pi / 4;
          final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
          if (i == 0) path.moveTo(p.dx, p.dy);
          else path.lineTo(p.dx, p.dy);
        }
        path.close();
        
        canvas.drawPath(path, Paint()
          ..color = d.color.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.radius * 0.5));
        canvas.drawPath(path, Paint()
          ..color = Colors.white.withValues(alpha: a * 1.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.radius * 0.2));
      } else {
        canvas.drawCircle(d.pos, d.radius,
            Paint()
              ..color = d.color.withValues(alpha: a)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.radius * 0.5)); 
        
        canvas.drawCircle(d.pos, d.radius * 0.4,
            Paint()
              ..color = Colors.white.withValues(alpha: a * 1.5)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.radius * 0.2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgDotPainter old) => true;
}

// ─── Trail/comet tail painter ───────────────────────────────────────
class _TrailPainter extends CustomPainter {
  final List<List<Offset>> trails;
  final List<double> opacities;
  _TrailPainter(this.trails, this.opacities);

  @override
  void paint(Canvas canvas, Size size) {
    final trailColors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFFA855F7),
    ];
    for (int i = 0; i < trails.length; i++) {
      final trail = trails[i];
      final opacity = opacities[i];
      if (trail.length < 2 || opacity <= 0) continue;

      for (int j = 1; j < trail.length; j++) {
        final t = j / trail.length;
        final a = opacity * t * 0.4;
        final r = (1 - t) * 6 + 2;
        canvas.drawCircle(
          trail[j],
          r,
          Paint()
            ..color = trailColors[i].withValues(alpha: a)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) => true;
}

// ─── Main intro screen ─────────────────────────────────────────────────
class JigsawIntroScreen extends StatefulWidget {
  const JigsawIntroScreen({super.key});
  @override
  State<JigsawIntroScreen> createState() => _JigsawIntroScreenState();
}

class _JigsawIntroScreenState extends State<JigsawIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  late AnimationController _loopCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _piecesAnim;
  late Animation<double> _sparkleAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _shrinkAnim;
  late Animation<double> _letterAnim;
  late Animation<double> _playAnim;

  final List<_Sparkle> _sparkles = [];

  final List<_BgDot> _bgDots = [];
  final _rng = Random();

  final List<List<Offset>> _pieceTrails = [[], [], [], []];
  final List<double> _trailOpacities = [1, 1, 1, 1];

  static const _flyFrom = [
    Offset(-1.5, -0.3),  // from left
    Offset(0.3, -1.5),   // from top
    Offset(1.5, 0.3),    // from right
    Offset(-0.3, 1.5),   // from bottom
  ];
  static const _startRot = [-1.2, 0.9, 1.0, -0.8];
  static const _title = 'PUZZLE';

  static const _letterColors = [
    Color(0xFFE53935), // P - Strawberry Red
    Color(0xFFFF6D00), // U - Tangerine Orange
    Color(0xFFFFD600), // Z - Lemon Yellow
    Color(0xFF00C853), // Z - Lime Green
    Color(0xFF2979FF), // L - Blueberry Blue
    Color(0xFFAA00FF), // E - Grape Purple
  ];

  final _pieceSoundPlayed = <int, bool>{};
  final _letterSoundPlayed = <int, bool>{};
  bool _snapSoundPlayed = false;

  @override
  void initState() {
    super.initState();

    JigsawSoundService().startBackgroundMusic();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000), 
    );

    _piecesAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.50, curve: Curves.linear),
    ));

    _sparkleAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.48, 0.60, curve: Curves.easeOut),
    ));

    _bounceAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.50, 0.62, curve: Curves.easeInOut),
    ));

    _shrinkAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.58, 0.68, curve: Curves.easeInOutCubic),
    ));

    _letterAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.67, 0.82, curve: Curves.easeOut),
    ));

    _playAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.86, 0.95, curve: Curves.elasticOut),
    ));

    _loopCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 15)) 
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _initSparkles();
    _initBgDots();

    _masterCtrl.addListener(_onTick);
    _masterCtrl.forward();
  }

  void _onTick() {
    final asmT = _piecesAnim.value;
    for (int i = 0; i < 4; i++) {
      final raw = ((asmT - i * 0.25) * 4).clamp(0.0, 1.0);
      if (raw > 0.05 && raw < 0.99 && _pieceSoundPlayed[i] != true) {
        _pieceSoundPlayed[i] = true;
        JigsawSoundService().playPickup(); 
      }
    }
    if (!_snapSoundPlayed && asmT >= 0.98) {
      _snapSoundPlayed = true;
      JigsawSoundService().playSnap();
    }
    final lp = _letterAnim.value;
    for (int i = 0; i < _title.length; i++) {
      final t = (lp * _title.length - i).clamp(0.0, 1.0);
      if (t > 0.3 && _letterSoundPlayed[i] != true) {
        _letterSoundPlayed[i] = true;
        JigsawSoundService().playTap();
      }
    }
  }

  void _initSparkles() {
    final colors = [
      Colors.white, const Color(0xFFFFD700), const Color(0xFFFF69B4),
      const Color(0xFF87CEEB), const Color(0xFFFF6D00), const Color(0xFFAA00FF),
    ];
    for (int i = 0; i < 65; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      _sparkles.add(_Sparkle(
        Offset(cos(a), sin(a)),
        0.3 + _rng.nextDouble() * 1.8,
        colors[_rng.nextInt(colors.length)],
        2 + _rng.nextDouble() * 6,
      ));
    }
  }

  void _initBgDots() {
    final confettiColors = [
      const Color(0xFFE53935), const Color(0xFFFF6D00),
      const Color(0xFFFFD600), const Color(0xFF00C853),
      const Color(0xFF2979FF), const Color(0xFFAA00FF),
      const Color(0xFFFF69B4), const Color(0xFF00BCD4),
    ];
    for (int i = 0; i < 80; i++) {
      _bgDots.add(_BgDot(
        Offset(_rng.nextDouble() * 1200 - 50, _rng.nextDouble() * 900 - 50),
        3 + _rng.nextDouble() * 6,
        _rng.nextDouble() * 2 * pi,
        confettiColors[_rng.nextInt(confettiColors.length)],
        isStar: false,
      ));
    }
    for (int i = 0; i < 15; i++) {
      _bgDots.add(_BgDot(
        Offset(_rng.nextDouble() * 1200 - 50, _rng.nextDouble() * 900 - 50),
        8 + _rng.nextDouble() * 14,
        _rng.nextDouble() * 2 * pi,
        confettiColors[_rng.nextInt(confettiColors.length)],
        isStar: true,
      ));
    }
    final pieceColors = [
      const Color(0xFFE53935), const Color(0xFF00C853),
      const Color(0xFF2979FF), const Color(0xFFAA00FF),
      const Color(0xFFFF6D00), const Color(0xFFFF69B4),
    ];
    final edgePositions = <Offset>[];
    for (int i = 0; i < 5; i++) {
      edgePositions.add(Offset(50 + _rng.nextDouble() * 1000, 10 + _rng.nextDouble() * 50));
      edgePositions.add(Offset(50 + _rng.nextDouble() * 1000, 720 + _rng.nextDouble() * 60));
    }
    for (int i = 0; i < 3; i++) {
      edgePositions.add(Offset(5 + _rng.nextDouble() * 40, 60 + _rng.nextDouble() * 650));
      edgePositions.add(Offset(1080 + _rng.nextDouble() * 60, 60 + _rng.nextDouble() * 650));
    }
    for (int i = 0; i < 6; i++) {
      edgePositions.add(Offset(150 + _rng.nextDouble() * 800, 100 + _rng.nextDouble() * 550));
    }
    for (final pos in edgePositions) {
      _bgDots.add(_BgDot(
        pos,
        14 + _rng.nextDouble() * 16,
        _rng.nextDouble() * 2 * pi,
        pieceColors[_rng.nextInt(pieceColors.length)].withValues(alpha: 0.8),
        isStar: false,
        isPuzzlePiece: true,
      ));
    }
  }

  void _goToCategories() {
    JigsawSoundService().playTap();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (c, a1, a2) => const JigsawCategoryScreen(),
      transitionsBuilder: (c, anim, a2, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _masterCtrl.removeListener(_onTick);
    _masterCtrl.dispose();
    _loopCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _stopMusicAndRestorePortrait() {
    JigsawSoundService().stopBackgroundMusic();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Offset _getFlightOffset(int i, double raw, double sw, double sh) {
    final linear = 1 - Curves.easeOutBack.transform(raw);
    final base = Offset(
      _flyFrom[i].dx * sw * 0.5 * linear,
      _flyFrom[i].dy * sh * 0.5 * linear,
    );
    final curveAmount = sin(raw * pi) * (i.isEven ? 60.0 : -60.0);
    return Offset(
      base.dx + (i < 2 ? curveAmount : -curveAmount),
      base.dy + (i.isOdd ? curveAmount : -curveAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final imgSize = min(sw, sh) * 0.65;
    final tabR = imgSize * 0.055;
    final cornerR = imgSize * 0.08;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _stopMusicAndRestorePortrait();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), 
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_masterCtrl, _loopCtrl, _pulseCtrl, _shimmerCtrl]),
        builder: (context, _) {
          final asmT = _piecesAnim.value;
          final spkT = _sparkleAnim.value;
          final bncT = _bounceAnim.value;
          final shrT = _shrinkAnim.value;

          final bounceScale = bncT <= 0.5
              ? 1.0 + 0.10 * (bncT * 2)
              : 1.10 - 0.10 * ((bncT - 0.5) * 2);
          
          final shrinkScale = 1.0 - shrT * 0.15; 
          final imgScale = bounceScale * shrinkScale;

          for (int i = 0; i < 4; i++) {
            final raw = ((asmT - i * 0.25) * 4).clamp(0.0, 1.0);
            final offset = _getFlightOffset(i, raw, sw, sh);
            
            final cx = sw / 2 + offset.dx;
            final cy = sh / 2 + offset.dy; 
            
            if (raw < 0.98 && asmT > (i * 0.25)) {
              _pieceTrails[i].add(Offset(cx, cy));
              if (_pieceTrails[i].length > 15) {
                _pieceTrails[i].removeAt(0);
              }
              _trailOpacities[i] = (1 - raw).clamp(0.0, 1.0);
            } else {
              _trailOpacities[i] = 0;
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
              ),
            ),
            child: Stack(
              children: [
                // Rainbow corner glows
                Positioned(
                  left: -sw * 0.15, top: -sh * 0.15,
                  child: Container(
                    width: sw * 0.5, height: sh * 0.5,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [const Color(0xFFFFB3BA).withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -sw * 0.15, top: -sh * 0.15,
                  child: Container(
                    width: sw * 0.5, height: sh * 0.5,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [const Color(0xFFBBDEFB).withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -sw * 0.15, bottom: -sh * 0.15,
                  child: Container(
                    width: sw * 0.5, height: sh * 0.5,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [const Color(0xFFFFF9C4).withValues(alpha: 0.7), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -sw * 0.15, bottom: -sh * 0.15,
                  child: Container(
                    width: sw * 0.5, height: sh * 0.5,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [const Color(0xFFC8E6C9).withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Confetti dots and pieces
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BgDotPainter(_bgDots, _loopCtrl.value * 20),
                  ),
                ),
                // Piece trails
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(_pieceTrails, _trailOpacities),
                  ),
                ),
                // Main content: Row layout
                Padding(
                  padding: EdgeInsets.only(left: sw * 0.08, right: sw * 0.05),
                  child: Row(
                    children: [
                      // ═══ LEFT: Puzzle Image with white frame + rainbow glow ═══
                      Transform.translate(
                        offset: const Offset(5, -8),
                        child: Transform.rotate(
                          angle: -0.03,
                          child: Transform.scale(
                            scale: imgScale,
                            child: Container(
                          width: imgSize + 16,
                          height: imgSize + 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cornerR + 8),
                            color: asmT > 0.95 ? Colors.white : Colors.transparent,
                            boxShadow: asmT > 0.95 ? [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.4 * ((asmT - 0.95) * 20).clamp(0.0, 1.0)),
                                blurRadius: 20, spreadRadius: 2,
                                offset: const Offset(-6, -6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF00C853).withValues(alpha: 0.4 * ((asmT - 0.95) * 20).clamp(0.0, 1.0)),
                                blurRadius: 20, spreadRadius: 2,
                                offset: const Offset(6, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF2979FF).withValues(alpha: 0.4 * ((asmT - 0.95) * 20).clamp(0.0, 1.0)),
                                blurRadius: 20, spreadRadius: 2,
                                offset: const Offset(6, -6),
                              ),
                              BoxShadow(
                                color: const Color(0xFFFFD600).withValues(alpha: 0.4 * ((asmT - 0.95) * 20).clamp(0.0, 1.0)),
                                blurRadius: 20, spreadRadius: 2,
                                offset: const Offset(-6, 6),
                              ),
                            ] : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(cornerR),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (int i = 0; i < 4; i++)
                                    _buildPiece(i, imgSize, tabR, cornerR,
                                        asmT, sw, sh),
                                  if (spkT > 0 && spkT < 1)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _SparklePainter(
                                          _sparkles, spkT,
                                          Offset(imgSize / 2, imgSize / 2),
                                        ),
                                      ),
                                    ),
                                  if (spkT > 0 && spkT < 0.4)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(cornerR),
                                        child: Container(
                                          color: Colors.white.withValues(
                                              alpha: (0.4 - spkT) * 1.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                      ),
                      SizedBox(width: sw * 0.04),
                      // ═══ RIGHT: PUZZLE Text + Play Button ═══
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          // ── Title: letters falling from top ──
                          Stack(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_title.length, (i) {
                                  final t = ((_letterAnim.value - i * 0.1) * 2)
                                      .clamp(0.0, 1.0);
                                  final b = Curves.elasticOut.transform(t);
                                  
                                  final fallY = -120.0 * (1.0 - t);
                                  const letterTilts = [-0.08, 0.06, -0.10, 0.08, -0.05, 0.07];
                                  final targetTilt = letterTilts[i];

                                  return Transform.translate(
                                    offset: Offset(0, fallY),
                                    child: Transform.rotate(
                                      angle: targetTilt * b,
                                      child: Transform.scale(
                                        scale: 0.1 + 0.9 * b,
                                      child: Opacity(
                                        opacity: t.clamp(0.0, 1.0),
                                        child: Text(
                                          _title[i],
                                          style: TextStyle(
                                            fontSize: 56,
                                            fontWeight: FontWeight.w900,
                                            color: _letterColors[i],
                                            letterSpacing: 2,
                                            shadows: [
                                              Shadow(
                                                color: _letterColors[i]
                                                    .withValues(alpha: 0.7),
                                                offset: const Offset(0, 3),
                                                blurRadius: 8,
                                              ),
                                              Shadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                offset: const Offset(2, 4),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // ── Play button: rises from bottom with punch ──
                          Opacity(
                            opacity: _playAnim.value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 100 * (1.0 - _playAnim.value.clamp(0.0, 1.0))),
                              child: Transform.scale(
                                scale: (0.3 +
                                        0.7 *
                                            _playAnim.value.clamp(0.0, 1.0)) *
                                    (1.0 + _pulseCtrl.value * 0.10),
                                child: GestureDetector(
                                  onTap: _goToCategories,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF69F0AE),
                                          Color(0xFF00C853),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00C853)
                                              .withValues(
                                                  alpha: 0.3 +
                                                      _pulseCtrl.value * 0.35),
                                          blurRadius:
                                              18 + _pulseCtrl.value * 14,
                                          spreadRadius:
                                              _pulseCtrl.value * 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildPiece(int i, double imgSize, double tabR, double cornerR,
      double asmT, double sw, double sh) {
    final raw = ((asmT - i * 0.25) * 4).clamp(0.0, 1.0);
    final offset = _getFlightOffset(i, raw, sw, sh);
    final rot = _startRot[i] * (1 - Curves.easeOutBack.transform(raw));

    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rot,
        child: Opacity(
          opacity: raw > 0 ? 1.0 : 0.0, 
          child: Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerR),
              boxShadow: raw < 1.0
                  ? [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.35 * (1 - raw)),
                        blurRadius: 28 * (1 - raw),
                        offset: Offset(offset.dx * 0.03, offset.dy * 0.03),
                      ),
                    ]
                  : null,
            ),
            child: ClipPath(
              clipper: _JigsawQuadrantClipper(
                  quadrant: i, tabR: tabR, cornerR: cornerR),
              child: Image.asset(
                'assets/jigsaw/webp/animals/lion_cub.webp',
                width: imgSize,
                height: imgSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
