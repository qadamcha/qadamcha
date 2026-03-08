import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/game_data.dart';
import '../services/jigsaw_sound_service.dart';
import 'jigsaw_level_screen.dart';

class JigsawCategoryScreen extends StatefulWidget {
  const JigsawCategoryScreen({super.key});
  @override
  State<JigsawCategoryScreen> createState() => _JigsawCategoryScreenState();
}

class _JigsawCategoryScreenState extends State<JigsawCategoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _kVirtualCount = 10000;
  late PageController _pageCtrl;
  double _currentPage = 0;
  late AnimationController _loopCtrl;

  // Background confetti dots
  final List<_ConfettiDot> _confettiDots = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();

    final startIndex =
        (_kVirtualCount ~/ 2) - ((_kVirtualCount ~/ 2) % jigsawCategories.length);
    _pageCtrl = PageController(
      viewportFraction: 0.42,
      initialPage: startIndex,
    );
    _currentPage = startIndex.toDouble();
    _pageCtrl.addListener(() {
      setState(() {
        _currentPage = _pageCtrl.page ?? _currentPage;
      });
    });

    _loopCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _loopCtrl.addListener(() => setState(() {}));

    _initConfetti();
  }

  void _initConfetti() {
    final confettiColors = [
      const Color(0xFFE53935), const Color(0xFFFF6D00),
      const Color(0xFFFFD600), const Color(0xFF00C853),
      const Color(0xFF2979FF), const Color(0xFFAA00FF),
      const Color(0xFFFF69B4), const Color(0xFF00BCD4),
    ];
    // Small confetti dots
    for (int i = 0; i < 60; i++) {
      _confettiDots.add(_ConfettiDot(
        Offset(_rng.nextDouble() * 1200 - 50, _rng.nextDouble() * 900 - 50),
        2 + _rng.nextDouble() * 5,
        _rng.nextDouble() * 2 * pi,
        confettiColors[_rng.nextInt(confettiColors.length)],
        isPiece: false,
      ));
    }
    // Puzzle piece silhouettes
    final pieceColors = [
      const Color(0xFFE53935), const Color(0xFF00C853),
      const Color(0xFF2979FF), const Color(0xFFAA00FF),
      const Color(0xFFFF6D00), const Color(0xFFFF69B4),
    ];
    for (int i = 0; i < 14; i++) {
      _confettiDots.add(_ConfettiDot(
        Offset(_rng.nextDouble() * 1200 - 50, _rng.nextDouble() * 900 - 50),
        12 + _rng.nextDouble() * 14,
        _rng.nextDouble() * 2 * pi,
        pieceColors[_rng.nextInt(pieceColors.length)].withValues(alpha: 0.7),
        isPiece: true,
      ));
    }
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _loopCtrl.dispose();
    JigsawSoundService().stopBackgroundMusic();
    _restorePortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _restorePortrait();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // Rainbow corner glows
              Positioned(
                left: -sw * 0.15, top: -sh * 0.15,
                child: Container(
                  width: sw * 0.5, height: sh * 0.5,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [const Color(0xFFFFB3BA).withValues(alpha: 0.5), Colors.transparent],
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
                      colors: [const Color(0xFFBBDEFB).withValues(alpha: 0.5), Colors.transparent],
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
                      colors: [const Color(0xFFFFF9C4).withValues(alpha: 0.6), Colors.transparent],
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
                      colors: [const Color(0xFFC8E6C9).withValues(alpha: 0.5), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Confetti dots + puzzle pieces
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConfettiPainter(_confettiDots, _loopCtrl.value * 20),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _kVirtualCount,
                        itemBuilder: (context, index) {
                          final realIndex = index % jigsawCategories.length;
                          final cat = jigsawCategories[realIndex];

                          final distance = (_currentPage - index).abs();
                          final scale = (1.0 - (distance * 0.25)).clamp(0.7, 1.0);
                          final opacity = (1.0 - (distance * 0.3)).clamp(0.6, 1.0);

                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: _CategoryCard(category: cat),
                            ),
                          );
                        },
                      ),
                    ),
                    // Colorful dot indicators
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(jigsawCategories.length, (i) {
                          final realCurrent =
                              _currentPage.round() % jigsawCategories.length;
                          final isActive = realCurrent == i;
                          final dotColors = [
                            const Color(0xFFE53935),
                            const Color(0xFFFF6D00),
                            const Color(0xFF00C853),
                            const Color(0xFF2979FF),
                            const Color(0xFFAA00FF),
                          ];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? dotColors[i % dotColors.length]
                                  : Colors.grey.withValues(alpha: 0.3),
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: dotColors[i % dotColors.length].withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ] : [],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // Back button (Stack'da oxirida — touch oladi)
              Positioned(
                top: 8,
                left: 8,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black54, size: 28),
                    onPressed: () {
                      _restorePortrait();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final JigsawCategoryData category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final c1 = Color(int.parse(category.gradientColors[0], radix: 16));
    final previewImage = category.levels.isNotEmpty
        ? category.levels[0].imagePath
        : '';

    return GestureDetector(
      onTap: () {
        JigsawSoundService().playTap();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => JigsawLevelScreen(category: category)),
        );
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: c1.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: c1.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (previewImage.isNotEmpty)
                    Image.asset(previewImage, fit: BoxFit.cover),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background confetti data ───
class _ConfettiDot {
  final Offset pos;
  final double radius;
  final double phase;
  final Color color;
  final bool isPiece;
  _ConfettiDot(this.pos, this.radius, this.phase, this.color, {this.isPiece = false});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiDot> dots;
  final double tick;
  _ConfettiPainter(this.dots, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final a = 0.4 + 0.2 * sin(tick * 2 + d.phase).abs();

      if (d.isPiece) {
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
          ..color = d.color.withValues(alpha: a * 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12));
        canvas.restore();
      } else {
        // Simple confetti dot
        canvas.drawCircle(d.pos, d.radius,
            Paint()
              ..color = d.color.withValues(alpha: a * 0.8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
