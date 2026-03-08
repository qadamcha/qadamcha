import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/game_data.dart';
import '../services/jigsaw_storage_service.dart';
import '../services/jigsaw_sound_service.dart';
import '../utils/jigsaw_clipper.dart';

class JigsawGameScreen extends StatefulWidget {
  final JigsawLevelData level;
  final int gridSize;
  const JigsawGameScreen({super.key, required this.level, required this.gridSize});
  @override
  State<JigsawGameScreen> createState() => _JigsawGameScreenState();
}

class _JigsawGameScreenState extends State<JigsawGameScreen> with TickerProviderStateMixin {
  ui.Image? _fullImage;
  List<PuzzlePiece> _pieces = [];
  List<List<Map<String, int>>> _edgeConfig = [];
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _hintOn = false;
  bool _gameWon = false;
  bool _navigatingToNext = false;
  late ConfettiController _confettiCtrl;

  // Win animation
  late AnimationController _winAnimCtrl;
  late Animation<double> _winScale;
  late Animation<double> _winOpacity;

  // Snap animation
  int? _snapAnimPieceId;
  late AnimationController _snapCtrl;
  late Animation<double> _snapScale;

  @override
  void initState() {
    super.initState();
    // Landscape rejimini ta'minlash (pushReplacement orqali kelganda ham)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 3));
    _winAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _winScale = Tween(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _winAnimCtrl, curve: Curves.easeOutBack),
    );
    _winOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _winAnimCtrl, curve: const Interval(0.0, 0.4)),
    );
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut));
    _snapCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _snapAnimPieceId = null);
      }
    });
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.level.imagePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _fullImage = frame.image;
    });
    _initPuzzle();
    _startTimer();
  }

  void _initPuzzle() {
    final n = widget.gridSize;
    _edgeConfig = EdgeConfigGenerator.generate(n, n);
    _pieces = [];
    _layoutDone = false;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final id = r * n + c;
        _pieces.add(PuzzlePiece(
          id: id,
          row: r,
          col: c,
          rows: n,
          cols: n,
          currentOffset: Offset.zero,
          correctOffset: Offset.zero,
          topEdge: _edgeConfig[r][c]['top']!,
          rightEdge: _edgeConfig[r][c]['right']!,
          bottomEdge: _edgeConfig[r][c]['bottom']!,
          leftEdge: _edgeConfig[r][c]['left']!,
        ));
      }
    }
    // Randomize piece order in tray
    _pieces.shuffle(Random());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameWon && mounted) {
        setState(() => _seconds++);
      }
    });
  }

  // Board layout
  double _pieceWidth = 0;
  double _pieceHeight = 0;
  double _tabSize = 0;
  Offset _boardOrigin = Offset.zero;
  double _boardW = 0;
  double _boardH = 0;
  bool _layoutDone = false;

  int? _draggingPieceId;

  // Sparkle particles for snap effect
  List<_SparkleParticle> _sparkles = [];

  void _checkSnap(PuzzlePiece piece) {
    final dist = (piece.currentOffset - piece.correctOffset).distance;
    // Magnet effect: smooth attraction when within 0.7× piece width
    if (dist < _pieceWidth * 0.7) {
      setState(() {
        piece.currentOffset = piece.correctOffset;
        piece.isPlaced = true;
        _moves++;
        // Trigger snap animation
        _snapAnimPieceId = piece.id;
        _snapCtrl.forward(from: 0);
        // Spawn sparkle particles at piece center
        final cx = piece.correctOffset.dx + _pieceWidth / 2;
        final cy = piece.correctOffset.dy + _pieceHeight / 2;
        _spawnSparkles(cx, cy);
      });
      JigsawSoundService().playSnap();
      _checkWin();
    } else {
      JigsawSoundService().playWrong();
      setState(() => _moves++);
    }
  }

  void _spawnSparkles(double cx, double cy) {
    final rng = Random();
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF69B4), // Pink
      const Color(0xFF00BFFF), // Sky blue
      const Color(0xFF7CFC00), // Green
      const Color(0xFFFF6347), // Coral
      const Color(0xFFE040FB), // Purple
    ];
    final count = 25 + rng.nextInt(15); // 25-40 particles
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 100 + rng.nextDouble() * 150;
      _sparkles.add(_SparkleParticle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: colors[rng.nextInt(colors.length)],
        size: 10 + rng.nextDouble() * 12,
        life: 1.0,
      ));
    }
    if (_sparkles.length == count) _animateSparkles();
  }

  void _animateSparkles() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      setState(() {
        for (final s in _sparkles) {
          s.x += s.vx * 0.016;
          s.y += s.vy * 0.016;
          s.vy += 80 * 0.016; // more gravity
          s.life -= 0.016 / 0.9; // fade over 900ms
          s.size *= 0.997; // shrink slightly over time
        }
        _sparkles.removeWhere((s) => s.life <= 0);
      });
      return _sparkles.isNotEmpty;
    });
  }

  void _checkWin() {
    if (_pieces.every((p) => p.isPlaced)) {
      setState(() => _gameWon = true);
      _confettiCtrl.play();
      _timer?.cancel();
      JigsawSoundService().playVictory();
      final stars = _calculateStars();
      JigsawStorageService.saveLevelCompleted(
          widget.level.id, stars, _seconds, _moves);
      // Start win animation: zoom image to center
      _winAnimCtrl.forward();
    }
  }

  int _calculateStars() {
    final n = widget.gridSize;
    final totalPieces = n * n;
    if (_moves <= totalPieces + 2) return 3;
    if (_moves <= totalPieces * 2) return 2;
    return 1;
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    _confettiCtrl.dispose();
    _snapCtrl.dispose();
    _winAnimCtrl.dispose();
    super.dispose();
  }

  void _doLayout(Size screenSize) {
    if (_pieces.isEmpty || _layoutDone) return;

    final n = widget.gridSize;
    final toolbarW = 60.0;
    final trayW = screenSize.width * 0.22;
    final padH = 20.0;
    final padV = 36.0;
    final availW = screenSize.width - toolbarW - trayW - padH * 2;
    final availH = screenSize.height - padV * 2;

    final boardSide = min(availW, availH);
    _boardW = boardSide;
    _boardH = boardSide;
    _pieceWidth = boardSide / n;
    _pieceHeight = boardSide / n;
    _tabSize = _pieceWidth * 0.22;

    _boardOrigin = Offset(
      toolbarW + padH + (availW - boardSide) / 2,
      padV + (availH - boardSide) / 2,
    );

    for (final piece in _pieces) {
      piece.correctOffset = Offset(
        _boardOrigin.dx + piece.col * _pieceWidth,
        _boardOrigin.dy + piece.row * _pieceHeight,
      );
    }
    _layoutDone = true;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_fullImage != null) {
      _doLayout(screenSize);
    }

    final n = widget.gridSize;
    final placedCount = _pieces.where((p) => p.isPlaced).length;
    final unplacedPieces = _pieces.where((p) => !p.isPlaced).toList();
    final trayW = screenSize.width * 0.22;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA8D8F0),
              Color(0xFFC8CFFF),
              Color(0xFFD9C5FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ───── LEFT TOOLBAR ─────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  border: Border(
                    right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _ToolBtn(
                      icon: Icons.arrow_back,
                      color: const Color(0xFFFF5555),
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 8),
                    _ToolBtn(
                      icon: _hintOn ? Icons.visibility : Icons.lightbulb,
                      color: _hintOn
                          ? const Color(0xFFFFC020)
                          : const Color(0xFF5BB8F5),
                      onTap: () {
                        JigsawSoundService().playTap();
                        setState(() => _hintOn = !_hintOn);
                      },
                    ),
                    const SizedBox(height: 8),
                    _ToolBtn(
                      icon: JigsawSoundService().soundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: JigsawSoundService().soundEnabled
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFF999999),
                      onTap: () {
                        JigsawSoundService().toggleSound();
                        JigsawSoundService().playTap();
                        setState(() {});
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ───── BOARD AREA ─────
            if (_fullImage != null && _layoutDone) ...[
              // Board background
              Positioned(
                left: _boardOrigin.dx - 4,
                top: _boardOrigin.dy - 4,
                child: Container(
                  width: _boardW + 8,
                  height: _boardH + 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5BB8F5).withValues(alpha: 0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5BB8F5).withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        // Hint image
                        if (_hintOn)
                          Opacity(
                            opacity: 0.25,
                            child: RawImage(
                              image: _fullImage,
                              width: _boardW,
                              height: _boardH,
                              fit: BoxFit.fill,
                            ),
                          ),
                        // Empty slots
                        ...List.generate(n * n, (idx) {
                          final r = idx ~/ n;
                          final c = idx % n;
                          // Find the piece that belongs to this grid position
                          final piece = _pieces.firstWhere(
                            (p) => p.row == r && p.col == c,
                          );
                          if (piece.isPlaced) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            left: c * _pieceWidth + 4,
                            top: r * _pieceHeight + 4,
                            child: _EmptySlot(
                              width: _pieceWidth,
                              height: _pieceHeight,
                              edgeConfig: _edgeConfig[r][c],
                              tabSize: _tabSize,
                              isDark: (r + c) % 2 == 1,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Placed pieces (with snap animation)
              ..._pieces.where((p) => p.isPlaced).map((piece) {
                final isAnimating = _snapAnimPieceId == piece.id;
                Widget child = _PieceWidget(
                  piece: piece,
                  fullImage: _fullImage!,
                  pieceWidth: _pieceWidth,
                  pieceHeight: _pieceHeight,
                  tabSize: _tabSize,
                  gridSize: n,
                );
                if (isAnimating) {
                  child = AnimatedBuilder(
                    animation: _snapScale,
                    builder: (_, ch) => Transform.scale(
                      scale: _snapScale.value,
                      child: ch,
                    ),
                    child: child,
                  );
                }
                return Positioned(
                  left: piece.correctOffset.dx -
                      (piece.leftEdge == 1 ? _tabSize : 0),
                  top: piece.correctOffset.dy -
                      (piece.topEdge == 1 ? _tabSize : 0),
                  child: child,
                );
              }),

              // ───── RIGHT TRAY PANEL ─────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: trayW,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFC8D8F0).withValues(alpha: 0.5),
                        const Color(0xFFD0DFFD).withValues(alpha: 0.7),
                      ],
                    ),
                    border: Border(
                      left: BorderSide(
                          color: const Color(0xFF5BB8F5).withValues(alpha: 0.35),
                          width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5BB8F5).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tray header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFF5BB8F5).withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '🧩 ${unplacedPieces.length} ta',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5588CC),
                            ),
                          ),
                        ),
                      ),
                      // Scrollable pieces
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: trayW * 0.06,
                            vertical: 6,
                          ),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: unplacedPieces
                                .map((piece) => _TrayPiece(
                                      piece: piece,
                                      fullImage: _fullImage!,
                                      pieceWidth: _pieceWidth,
                                      pieceHeight: _pieceHeight,
                                      tabSize: _tabSize,
                                      gridSize: n,
                                      trayW: trayW,
                                      onDragStarted: () {
                                        JigsawSoundService().playPickup();
                                        setState(
                                            () => _draggingPieceId = piece.id);
                                      },
                                      onDragEnd: (offset) {
                                        _handleTrayDrop(piece, offset);
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // (Draggable feedback handles the visual during drag)
            ],

            // ───── PROGRESS BAR (animated) ─────
            Positioned(
              left: 65,
              right: trayW + 5,
              bottom: 6,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        widthFactor: n * n > 0
                            ? placedCount.toDouble() / (n * n).toDouble()
                            : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5BB8F5),
                                Color(0xFFA78BFA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$placedCount/${n * n}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4488BB).withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // ───── SPARKLE PARTICLES (with glow) ─────
            ..._sparkles.map((s) => Positioned(
              left: s.x - s.size / 2,
              top: s.y - s.size / 2,
              child: Opacity(
                opacity: s.life.clamp(0.0, 1.0),
                child: Container(
                  width: s.size,
                  height: s.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.color,
                    boxShadow: [
                      BoxShadow(
                        color: s.color.withValues(alpha: 0.9),
                        blurRadius: s.size,
                        spreadRadius: s.size * 0.2,
                      ),
                    ],
                  ),
                ),
              ),
            )),
            // ───── WIN OVERLAY ─────
            if (_gameWon) _buildWinOverlay(),

            // Loading
            if (_fullImage == null)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF5BB8F5)),
                      SizedBox(height: 16),
                      Text('Rasm yuklanmoqda...',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4488BB))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTrayDrop(PuzzlePiece piece, Offset globalPos) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      setState(() => _draggingPieceId = null);
      return;
    }
    final localPos = box.globalToLocal(globalPos);

    // globalPos is the top-left of the Draggable feedback widget in screen coords.
    // The feedback widget includes tab space, so we need to find the CORE position.
    // Core area sits at (extraL, extraT) within the feedback widget.
    final extraL = piece.leftEdge == 1 ? _tabSize : 0.0;
    final extraT = piece.topEdge == 1 ? _tabSize : 0.0;

    // Core top-left in local coordinates
    piece.currentOffset = Offset(
      localPos.dx + extraL,
      localPos.dy + extraT,
    );
    _checkSnap(piece);
    setState(() => _draggingPieceId = null);
  }

  Widget _buildWinOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final displaySize = min(screenSize.width, screenSize.height) * 0.45;

    return AnimatedBuilder(
      animation: _winAnimCtrl,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: _winOpacity.value * 0.75),
            child: Stack(
              children: [
                // Centered image with Lottie behind
                Center(
                  child: Transform.scale(
                    scale: _winScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lottie stars animation BEHIND the image
                        SizedBox(
                          width: displaySize * 2.0,
                          height: displaySize * 2.0,
                          child: Lottie.asset(
                            'assets/animations/stars_animation.json',
                            repeat: false,
                            onLoaded: (composition) {
                              Future.delayed(composition.duration + const Duration(milliseconds: 500), () {
                                if (mounted && _gameWon) {
                                  _goToNextLevel();
                                }
                              });
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // If stars animation not found, auto-proceed after delay
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted && _gameWon) {
                                  _goToNextLevel();
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        // Completed puzzle image on top
                        Container(
                          width: displaySize,
                          height: displaySize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _fullImage != null
                                ? RawImage(
                                    image: _fullImage,
                                    width: displaySize,
                                    height: displaySize,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Left ribbon streamer
                Positioned(
                  left: 0,
                  top: screenSize.height * 0.15,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirection: -pi / 5,
                    emissionFrequency: 0.04,
                    numberOfParticles: 8,
                    maxBlastForce: 35,
                    minBlastForce: 15,
                    gravity: 0.08,
                    shouldLoop: false,
                    createParticlePath: (size) {
                      // Ribbon/streamer shape
                      return Path()
                        ..addRRect(RRect.fromRectAndRadius(
                          Rect.fromCenter(center: Offset.zero, width: size.width * 0.3, height: size.height * 1.2),
                          const Radius.circular(2),
                        ));
                    },
                    colors: const [
                      Color(0xFFFFD700), Color(0xFFFF69B4),
                      Color(0xFF00BFFF), Color(0xFF7CFC00),
                      Color(0xFFA855F7), Color(0xFFFF6347),
                    ],
                  ),
                ),
                // Right ribbon streamer
                Positioned(
                  right: 0,
                  top: screenSize.height * 0.15,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirection: -4 * pi / 5,
                    emissionFrequency: 0.04,
                    numberOfParticles: 8,
                    maxBlastForce: 35,
                    minBlastForce: 15,
                    gravity: 0.08,
                    shouldLoop: false,
                    createParticlePath: (size) {
                      return Path()
                        ..addRRect(RRect.fromRectAndRadius(
                          Rect.fromCenter(center: Offset.zero, width: size.width * 0.3, height: size.height * 1.2),
                          const Radius.circular(2),
                        ));
                    },
                    colors: const [
                      Color(0xFFFFD700), Color(0xFFFF69B4),
                      Color(0xFF00BFFF), Color(0xFF7CFC00),
                      Color(0xFFA855F7), Color(0xFFFF6347),
                    ],
                  ),
                ),
                // Top center burst
                Positioned(
                  left: screenSize.width / 2,
                  top: 0,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.06,
                    numberOfParticles: 15,
                    maxBlastForce: 20,
                    minBlastForce: 5,
                    gravity: 0.15,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFFFFD700), Color(0xFFFF69B4),
                      Color(0xFF00BFFF), Color(0xFFA855F7),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextLevel() {
    // Find current category
    final cat = jigsawCategories.firstWhere(
      (c) => c.levels.any((l) => l.id == widget.level.id),
      orElse: () => jigsawCategories.first,
    );
    final idx = cat.levels.indexWhere((l) => l.id == widget.level.id);
    if (idx >= 0 && idx < cat.levels.length - 1) {
      // Keyingi darajaga o'tish — landscape saqlansin
      _navigatingToNext = true;
      final nextLevel = cat.levels[idx + 1];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => JigsawGameScreen(
            level: nextLevel,
            gridSize: widget.gridSize,
          ),
        ),
      );
    } else {
      // Last level — go back to level selection
      Navigator.pop(context);
    }
  }

  void _resetGame() {
    setState(() {
      _gameWon = false;
      _moves = 0;
      _seconds = 0;
      _layoutDone = false;
      _initPuzzle();
    });
    _startTimer();
  }
}

// ───────── WIDGETS ─────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ToolBtn(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String value;
  const _StatPill({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5588CC))),
        ],
      ),
    );
  }
}

class _WinStat extends StatelessWidget {
  final String value;
  final String label;
  const _WinStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5588CC))),
        Text(label,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF99AACC))),
      ]),
    );
  }
}

/// A tray piece in the scrollable right panel.
/// Uses [Draggable] so users can drag it onto the board.
class _TrayPiece extends StatelessWidget {
  final PuzzlePiece piece;
  final ui.Image fullImage;
  final double pieceWidth;
  final double pieceHeight;
  final double tabSize;
  final int gridSize;
  final double trayW;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragEnd;

  const _TrayPiece({
    required this.piece,
    required this.fullImage,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.tabSize,
    required this.gridSize,
    required this.trayW,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Scale piece down to fit tray
    final extraL = piece.leftEdge == 1 ? tabSize : 0.0;
    final extraT = piece.topEdge == 1 ? tabSize : 0.0;
    final extraR = piece.rightEdge == 1 ? tabSize : 0.0;
    final extraB = piece.bottomEdge == 1 ? tabSize : 0.0;
    final totalW = pieceWidth + extraL + extraR;
    final totalH = pieceHeight + extraT + extraB;

    final traySlotW = (trayW - 30) / 2; // 2 columns in tray
    final scale = traySlotW / totalW;
    final displayW = totalW * scale;
    final displayH = totalH * scale;

    return Draggable<int>(
      data: piece.id,
      onDragStarted: onDragStarted,
      onDragEnd: (details) {
        onDragEnd(details.offset);
      },
      feedback: Transform.scale(
        scale: 1.0,
        child: _PieceWidget(
          piece: piece,
          fullImage: fullImage,
          pieceWidth: pieceWidth,
          pieceHeight: pieceHeight,
          tabSize: tabSize,
          gridSize: gridSize,
          showShadow: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: SizedBox(width: displayW, height: displayH),
      ),
      child: SizedBox(
        width: displayW,
        height: displayH,
        child: FittedBox(
          child: _PieceWidget(
            piece: piece,
            fullImage: fullImage,
            pieceWidth: pieceWidth,
            pieceHeight: pieceHeight,
            tabSize: tabSize,
            gridSize: gridSize,
            showShadow: true,
          ),
        ),
      ),
    );
  }
}

/// Renders a single jigsaw puzzle piece — clipped from the full image.
class _PieceWidget extends StatelessWidget {
  final PuzzlePiece piece;
  final ui.Image fullImage;
  final double pieceWidth;
  final double pieceHeight;
  final double tabSize;
  final int gridSize;
  final bool showShadow;

  const _PieceWidget({
    required this.piece,
    required this.fullImage,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.tabSize,
    required this.gridSize,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final extraL = piece.leftEdge == 1 ? tabSize : 0.0;
    final extraT = piece.topEdge == 1 ? tabSize : 0.0;
    final extraR = piece.rightEdge == 1 ? tabSize : 0.0;
    final extraB = piece.bottomEdge == 1 ? tabSize : 0.0;
    final totalW = pieceWidth + extraL + extraR;
    final totalH = pieceHeight + extraT + extraB;

    return SizedBox(
      width: totalW,
      height: totalH,
      child: CustomPaint(
        painter: _PiecePainter(
          image: fullImage,
          piece: piece,
          gridSize: gridSize,
          pieceWidth: pieceWidth,
          pieceHeight: pieceHeight,
          tabSize: tabSize,
          extraL: extraL,
          extraT: extraT,
          extraR: extraR,
          extraB: extraB,
        ),
        size: Size(totalW, totalH),
      ),
    );
  }
}

/// Draws the correct portion of the full image for a puzzle piece,
/// including expanded source rect for tab areas from neighboring pieces.
class _PiecePainter extends CustomPainter {
  final ui.Image image;
  final PuzzlePiece piece;
  final int gridSize;
  final double pieceWidth;
  final double pieceHeight;
  final double tabSize;
  final double extraL;
  final double extraT;
  final double extraR;
  final double extraB;

  _PiecePainter({
    required this.image,
    required this.piece,
    required this.gridSize,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.tabSize,
    required this.extraL,
    required this.extraT,
    required this.extraR,
    required this.extraB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Generate the clip path
    final clipPath = JigsawPiecePath.generatePath(
      pieceWidth: pieceWidth,
      pieceHeight: pieceHeight,
      topEdge: piece.topEdge,
      rightEdge: piece.rightEdge,
      bottomEdge: piece.bottomEdge,
      leftEdge: piece.leftEdge,
    ).shift(Offset(extraL, extraT));

    canvas.save();
    canvas.clipPath(clipPath);

    // Calculate source rect including tab areas from the full image
    final srcPieceW = image.width / gridSize;
    final srcPieceH = image.height / gridSize;
    final tabFraction = 0.22;

    // How much to extend the source rect for each tab
    final srcTabW = srcPieceW * tabFraction;
    final srcTabH = srcPieceH * tabFraction;

    // Base source position
    double srcL = piece.col * srcPieceW;
    double srcT = piece.row * srcPieceH;
    double srcR = (piece.col + 1) * srcPieceW;
    double srcB = (piece.row + 1) * srcPieceH;

    // Expand for tabs (tab protrudes into neighbor's image area)
    if (piece.leftEdge == 1) srcL -= srcTabW;
    if (piece.topEdge == 1) srcT -= srcTabH;
    if (piece.rightEdge == 1) srcR += srcTabW;
    if (piece.bottomEdge == 1) srcB += srcTabH;

    // Clamp to image bounds
    srcL = srcL.clamp(0, image.width.toDouble());
    srcT = srcT.clamp(0, image.height.toDouble());
    srcR = srcR.clamp(0, image.width.toDouble());
    srcB = srcB.clamp(0, image.height.toDouble());

    final src = Rect.fromLTRB(srcL, srcT, srcR, srcB);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    // Draw a subtle border around the piece shape
    if (true) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.5);
      canvas.drawPath(clipPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) {
    return old.piece.id != piece.id ||
        old.pieceWidth != pieceWidth;
  }
}

/// Empty slot showing where a piece should go.
class _EmptySlot extends StatelessWidget {
  final double width;
  final double height;
  final Map<String, int> edgeConfig;
  final double tabSize;
  final bool isDark;

  const _EmptySlot({
    required this.width,
    required this.height,
    required this.edgeConfig,
    required this.tabSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final top = edgeConfig['top'] ?? 0;
    final right = edgeConfig['right'] ?? 0;
    final bottom = edgeConfig['bottom'] ?? 0;
    final left = edgeConfig['left'] ?? 0;

    final extraL = left == 1 ? tabSize : 0.0;
    final extraT = top == 1 ? tabSize : 0.0;
    final extraR = right == 1 ? tabSize : 0.0;
    final extraB = bottom == 1 ? tabSize : 0.0;
    final totalW = width + extraL + extraR;
    final totalH = height + extraT + extraB;

    return Transform.translate(
      offset: Offset(-extraL, -extraT),
      child: SizedBox(
        width: totalW,
        height: totalH,
        child: ClipPath(
          clipper: JigsawClipper(
            pieceWidth: width,
            pieceHeight: height,
            topEdge: top,
            rightEdge: right,
            bottomEdge: bottom,
            leftEdge: left,
            tabSize: tabSize,
          ),
          child: Container(
            color: isDark
                ? const Color(0xFFD0D6E0).withValues(alpha: 0.5)
                : const Color(0xFFDCE3ED).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Particle data for snap sparkle effect.
class _SparkleParticle {
  double x, y, vx, vy, size, life;
  final Color color;
  _SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });
}
