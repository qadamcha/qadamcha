import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../data/coloring_storage.dart';
import '../engine/flood_fill_engine.dart';
import '../engine/sound_service.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/color_palette.dart';
import '../widgets/sound_settings_sheet.dart';

/// Flood Fill asosidagi bo'yash ekrani — Nana Banana uslubida
class ColoringScreen extends StatefulWidget {
  final ColoringImageInfo imageInfo;

  const ColoringScreen({super.key, required this.imageInfo});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen>
    with WidgetsBindingObserver {
  final FloodFillEngine _engine = FloodFillEngine();
  final TransformationController _transformController = TransformationController();
  int _selectedColorIndex = 0;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _completed = false;
  ui.Image? _displayImage;

  // Zoom + Tap uchun pointer tracking
  int _pointerCount = 0;
  Offset? _pointerDownPos;
  bool _wasDrag = false;
  BoxConstraints? _canvasConstraints;

  // ═══ PERFORMANCE: Const decorations ═══
  static const _bgGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFE0E7FF), Color(0xFFFCE7F3), Color(0xFFFEF3C7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService().init();
    _loadImage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundService().stopBgMusic();
    _transformController.dispose();
    _displayImage?.dispose();
    super.dispose();
  }

  /// App foreground/background holati — musiqani pause/resume qilish
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SoundService().stopBgMusic();
    } else if (state == AppLifecycleState.resumed && !_completed) {
      SoundService().playBgMusic();
    }
  }

  Future<void> _loadImage() async {
    try {
      final image = await _engine.loadImage(widget.imageInfo.assetPath);
      if (mounted) {
        setState(() {
          final oldImage = _displayImage;
          _displayImage = image;
          if (oldImage != null) oldImage.dispose();
          _isLoading = false;
        });
        // Rasm yuklangandan keyin background musiqa boshlash
        SoundService().playBgMusic();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasm yuklanmadi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pointer eventlardan tap va zoom ni farqlash
  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount == 1) {
      _pointerDownPos = event.localPosition;
      _wasDrag = false;
    } else {
      // 2+ barmaq = zoom, tap emas
      _wasDrag = true;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerDownPos != null && !_wasDrag) {
      final distance = (event.localPosition - _pointerDownPos!).distance;
      if (distance > 10) {
        _wasDrag = true; // drag/pan qildi, tap emas
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_pointerCount == 0 && !_wasDrag && _pointerDownPos != null) {
      // Bu haqiqiy tap — bo'yash
      _handleTap(event.localPosition);
    }
    if (_pointerCount == 0) {
      _pointerDownPos = null;
      _wasDrag = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_pointerCount == 0) {
      _pointerDownPos = null;
      _wasDrag = false;
    }
  }

  void _handleTap(Offset viewportPosition) {
    if (_isLoading || _isBusy || _displayImage == null || _completed) return;
    final constraints = _canvasConstraints;
    if (constraints == null) return;

    final imageWidth = _displayImage!.width.toDouble();
    final imageHeight = _displayImage!.height.toDouble();
    final boxWidth = constraints.maxWidth;
    final boxHeight = constraints.maxHeight;

    final scaleX = boxWidth / imageWidth;
    final scaleY = boxHeight / imageHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final scaledW = imageWidth * scale;
    final scaledH = imageHeight * scale;
    final offsetX = (boxWidth - scaledW) / 2;
    final offsetY = (boxHeight - scaledH) / 2;

    // Viewport koordinatalarini scene (rasm widget) koordinatalariga o'girish
    final scenePoint = _transformController.toScene(viewportPosition);

    final imgX = ((scenePoint.dx - offsetX) / scale).round();
    final imgY = ((scenePoint.dy - offsetY) / scale).round();

    if (imgX < 0 || imgX >= imageWidth || imgY < 0 || imgY >= imageHeight) {
      return;
    }

    _performFill(imgX, imgY);
  }

  Future<void> _performFill(int x, int y) async {
    _isBusy = true;
    try {
      HapticFeedback.lightImpact();

      final fillColor = ColoringPalette.colors[_selectedColorIndex];
      final newImage = await _engine.fillWithColor(
        x,
        y,
        (fillColor.r * 255).round(),
        (fillColor.g * 255).round(),
        (fillColor.b * 255).round(),
      );

      if (newImage != null && mounted) {
        final isComplete = _engine.isCompleted();
        SoundService().playFill();

        setState(() {
          final oldImage = _displayImage;
          _displayImage = newImage;
          if (oldImage != null) oldImage.dispose();
          
          if (isComplete && !_completed) {
            _completed = true;
          }
        });

        if (_completed) {
          // Bo'yash tugadi — musiqani to'xtatish
          SoundService().stopBgMusic();
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 400), () {
            SoundService().playSuccess();
            if (mounted) _showCelebrationDialog();
          });
        }
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _undo() async {
    if (!_engine.canUndo) return;
    HapticFeedback.selectionClick();
    SoundService().playUndo();

    final newImage = await _engine.undo();
    if (newImage != null && mounted) {
      final wasCompleted = _completed; // Oldin to'liq bo'yalganmi?
      setState(() {
        final oldImage = _displayImage;
        _displayImage = newImage;
        if (oldImage != null) oldImage.dispose();
        _completed = false;
      });
      
      // Agar rasm tugatilgan bo'lsa va orqaga qaytarilsa, musiqani yoqish kerak
      if (wasCompleted) {
        SoundService().playBgMusic();
      }
    }
  }

  Future<void> _clearAll() async {
    HapticFeedback.mediumImpact();
    // Zoomni qayta tiklash
    _transformController.value = Matrix4.identity();
    final newImage = await _engine.clearAll();
    if (mounted) {
      final wasCompleted = _completed;
      setState(() {
        final oldImage = _displayImage;
        _displayImage = newImage;
        if (oldImage != null) oldImage.dispose();
        _completed = false;
      });
      
      // Ilovani barchasini tozalagandan keyin musiqa qayta ishlashi kerak
      if (wasCompleted) {
        SoundService().playBgMusic();
      }
    }
  }

  Future<void> _saveAndExit() async {
    if (_displayImage == null) return;
    HapticFeedback.heavyImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Saqlanmoqda...'),
            duration: Duration(seconds: 1)),
      );
    }

    await ColoringStorage.saveImage(_displayImage!, widget.imageInfo);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.pop(context);
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CelebrationDialog(
        onSave: _saveAndExit,
        onClear: _clearAll,
        onExit: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _isLoading ? 0.0 : _engine.progress;

    return Scaffold(
      body: Container(
        decoration: _bgGradient,
        child: SafeArea(
          child: Column(
            children: [
              // ═══ TOP BAR ═══
              _buildTopBar(progress),
              SizedBox(height: 8.h),

              // ═══ PROGRESS BAR ═══
              _buildProgressBar(progress),
              SizedBox(height: 8.h),

              // ═══ CANVAS ═══
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h), // Kichik joy ajratamiz, palette ga tiqilmasligi uchun
                  child: _buildCanvas(),
                ),
              ),

              // ═══ COLOR PALETTE ═══
              // Qalamcha yuqoriga chiqishi uchun joy
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: ColoringPaletteWidget(
                  selectedIndex: _selectedColorIndex,
                  onColorSelected: (idx) {
                    setState(() => _selectedColorIndex = idx);
                  },
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 4.h),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TOP BAR — chunky 3D cartoon buttons
  // ═══════════════════════════════════════════════════════
  Widget _buildTopBar(double progress) {
    return Padding(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 10.h, bottom: 6.h), // SafeArea'dan tashqari qo'shimcha ochiq joy (notchlar uchun)
      child: Row(
        children: [
          // Back button
          _buildToolButton(
            icon: Icons.arrow_back_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () {
              SoundService().playPop();
              Navigator.pop(context);
            },
          ),
          SizedBox(width: 8.w),

          // Title
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.imageInfo.emoji,
                      style: TextStyle(fontSize: 22.sp)),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      widget.imageInfo.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // Progress badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _completed
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // Save button
          _buildToolButton(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF22C55E),
            onTap: () {
              SoundService().playPop();
              _saveAndExit();
            },
          ),
          SizedBox(width: 6.w),

          // Settings button (ovoz sozlamalari)
          _buildToolButton(
            icon: Icons.music_note_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () {
              SoundService().playPop();
              SoundSettingsSheet.show(context);
            },
          ),
          SizedBox(width: 6.w),

          // Undo button
          _buildToolButton(
            icon: Icons.undo_rounded,
            color: _engine.canUndo
                ? const Color(0xFFF97316)
                : const Color(0xFFD1D5DB),
            onTap: _engine.canUndo ? _undo : null,
          ),
          SizedBox(width: 6.w),

          // Clear button
          _buildToolButton(
            icon: Icons.delete_outline_rounded,
            color: _displayImage != null
                ? const Color(0xFFEF4444)
                : const Color(0xFFD1D5DB),
            onTap: _displayImage != null ? _clearAll : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isEnabled
                ? color.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PROGRESS BAR — fun cartoon style
  // ═══════════════════════════════════════════════════════
  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 16.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Stack(
            children: [
              // Progress fill
              FractionallySizedBox(
                widthFactor: _isLoading ? 0 : progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _completed
                          ? [const Color(0xFF22C55E), const Color(0xFF4ADE80)]
                          : [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              // Star decorations
              if (!_isLoading)
                Positioned(
                  right: 4.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      _completed ? '⭐' : '🎨',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CANVAS — white card with shadow
  // ═══════════════════════════════════════════════════════
  Widget _buildCanvas() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                ),
              )
            : _displayImage == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('😔', style: TextStyle(fontSize: 40.sp)),
                        SizedBox(height: 8.h),
                        Text(
                          'Rasm yuklanmadi',
                          style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      _canvasConstraints = constraints;
                      return RepaintBoundary(
                        child: Listener(
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 1.0,
                            maxScale: 5.0,
                            panEnabled: true,
                            scaleEnabled: true,
                            child: Center(
                              child: RawImage(
                                image: _displayImage,
                                fit: BoxFit.contain,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
