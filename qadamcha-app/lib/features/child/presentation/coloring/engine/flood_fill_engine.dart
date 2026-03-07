import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// Flood Fill Engine v5 — Performance Optimized
///
/// Optimizatsiyalar:
/// 1. Cached progress — har frame'da 4M piksel aylanmaydi
/// 2. Incremental progress tracking — faqat o'zgargan piksellar hisoblanadi
/// 3. Pre-computed paintable count — faqat bir marta hisoblanadi
class FloodFillEngine {
  late Uint8List _pixels;
  late int _width;
  late int _height;
  late Uint8List _originalPixels;

  /// Binary mask: 1 = chegara (qora), 0 = bo'yash mumkin (oq)
  late Uint8List _boundaryMask;

  /// Background mask: 1 = tashqi fon (progress hisobga kiritilmaydi)
  late Uint8List _backgroundMask;

  /// ═══ PERFORMANCE: Cached progress ═══
  /// Har frame'da barcha piksellarni aylashning o'rniga,
  /// faqat o'zgargan piksellarni kuzatamiz
  int _paintableCount = 0;  // Jami bo'yash mumkin piksellar (bir marta hisoblanadi)
  int _coloredCount = 0;    // Hozirgi bo'yalgan piksellar soni
  double _cachedProgress = 0.0;

  /// Delta-based undo stack
  final List<_FillDelta> _undoStack = [];
  static const int _maxUndoSteps = 15;

  bool get canUndo => _undoStack.isNotEmpty;
  int get width => _width;
  int get height => _height;

  /// ═══ PERFORMANCE: Cached progress getter — O(1) ═══
  double get progress => _cachedProgress;

  bool isCompleted() => _cachedProgress >= 0.99;

  /// ═══ PERFORMANCE: Progress'ni yangilash — O(1) ═══
  void _updateProgress() {
    _cachedProgress = _paintableCount == 0 ? 1.0 : _coloredCount / _paintableCount;
  }

  /// Rasmni yuklash va advanced pre-process
  Future<ui.Image> loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    _width = image.width;
    _height = image.height;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    _pixels = Uint8List.fromList(byteData!.buffer.asUint8List());

    // ═══ ADVANCED PRE-PROCESSING PIPELINE ═══
    _advancedPreProcess();
    _detectBackground();

    _originalPixels = Uint8List.fromList(_pixels);

    // ═══ PERFORMANCE: Paintable count'ni bir marta hisoblash ═══
    _computeInitialProgress();

    // Xotira tozalash
    image.dispose();
    codec.dispose();

    return _createImage();
  }

  /// ═══ PERFORMANCE: Initial progress — bir marta O(n), keyin O(1) ═══
  void _computeInitialProgress() {
    final totalPixels = _width * _height;
    _paintableCount = 0;
    _coloredCount = 0;

    for (int i = 0; i < totalPixels; i++) {
      if (_boundaryMask[i] == 0 && _backgroundMask[i] == 0) {
        _paintableCount++;
        // Boshlang'ich holatda hamma oq — colored = 0
      }
    }
    _updateProgress();
  }

  /// Advanced pre-processing: Grayscale → Otsu → Dilation → Binary
  void _advancedPreProcess() {
    final totalPixels = _width * _height;

    // Step 1: Grayscale
    final grayscale = Uint8List(totalPixels);
    for (int i = 0; i < totalPixels; i++) {
      final offset = i * 4;
      final r = _pixels[offset];
      final g = _pixels[offset + 1];
      final b = _pixels[offset + 2];
      final a = _pixels[offset + 3];

      if (a < 128) {
        grayscale[i] = 255;
      } else {
        grayscale[i] = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
      }
    }

    // Step 2: Otsu threshold
    final threshold = _otsuThreshold(grayscale);

    // Step 3: Binary mask
    _boundaryMask = Uint8List(totalPixels);
    for (int i = 0; i < totalPixels; i++) {
      _boundaryMask[i] = grayscale[i] < threshold ? 1 : 0;
    }

    // Step 4: Morphological dilation
    _dilateBoundary();

    // Step 5: Piksellarni sof qora/oq ga yozish
    for (int i = 0; i < totalPixels; i++) {
      final offset = i * 4;
      if (_boundaryMask[i] == 1) {
        _pixels[offset] = 0;
        _pixels[offset + 1] = 0;
        _pixels[offset + 2] = 0;
        _pixels[offset + 3] = 255;
      } else {
        _pixels[offset] = 255;
        _pixels[offset + 1] = 255;
        _pixels[offset + 2] = 255;
        _pixels[offset + 3] = 255;
      }
    }
  }

  /// Otsu's method
  int _otsuThreshold(Uint8List grayscale) {
    final histogram = List<int>.filled(256, 0);
    for (final val in grayscale) {
      histogram[val]++;
    }

    final total = grayscale.length;
    double sumAll = 0;
    for (int i = 0; i < 256; i++) {
      sumAll += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    double maxVariance = 0;
    int bestThreshold = 128;

    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;

      final wF = total - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];

      final mB = sumB / wB;
      final mF = (sumAll - sumB) / wF;

      final variance = wB.toDouble() * wF.toDouble() * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        bestThreshold = t;
      }
    }

    return math.min(bestThreshold + 30, 240);
  }

  /// Morphological dilation
  void _dilateBoundary() {
    final totalPixels = _width * _height;
    final dilated = Uint8List.fromList(_boundaryMask);

    for (int y = 1; y < _height - 1; y++) {
      for (int x = 1; x < _width - 1; x++) {
        final idx = y * _width + x;
        if (_boundaryMask[idx] == 1) {
          dilated[idx - 1] = 1;
          dilated[idx + 1] = 1;
          dilated[idx - _width] = 1;
          dilated[idx + _width] = 1;
        }
      }
    }

    for (int i = 0; i < totalPixels; i++) {
      _boundaryMask[i] = dilated[i];
    }
  }

  /// Background detection
  void _detectBackground() {
    final totalPixels = _width * _height;
    _backgroundMask = Uint8List(totalPixels);

    final visited = Uint8List(totalPixels);
    final queue = Queue<int>();

    for (int x = 0; x < _width; x++) {
      final topIdx = x;
      if (_boundaryMask[topIdx] == 0 && visited[topIdx] == 0) {
        visited[topIdx] = 1;
        queue.add(topIdx);
      }
      final bottomIdx = (_height - 1) * _width + x;
      if (_boundaryMask[bottomIdx] == 0 && visited[bottomIdx] == 0) {
        visited[bottomIdx] = 1;
        queue.add(bottomIdx);
      }
    }
    for (int y = 0; y < _height; y++) {
      final leftIdx = y * _width;
      if (_boundaryMask[leftIdx] == 0 && visited[leftIdx] == 0) {
        visited[leftIdx] = 1;
        queue.add(leftIdx);
      }
      final rightIdx = y * _width + (_width - 1);
      if (_boundaryMask[rightIdx] == 0 && visited[rightIdx] == 0) {
        visited[rightIdx] = 1;
        queue.add(rightIdx);
      }
    }

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      _backgroundMask[idx] = 1;

      final px = idx % _width;
      final py = idx ~/ _width;

      if (px > 0) {
        final n = idx - 1;
        if (visited[n] == 0 && _boundaryMask[n] == 0) {
          visited[n] = 1;
          queue.add(n);
        }
      }
      if (px < _width - 1) {
        final n = idx + 1;
        if (visited[n] == 0 && _boundaryMask[n] == 0) {
          visited[n] = 1;
          queue.add(n);
        }
      }
      if (py > 0) {
        final n = idx - _width;
        if (visited[n] == 0 && _boundaryMask[n] == 0) {
          visited[n] = 1;
          queue.add(n);
        }
      }
      if (py < _height - 1) {
        final n = idx + _width;
        if (visited[n] == 0 && _boundaryMask[n] == 0) {
          visited[n] = 1;
          queue.add(n);
        }
      }
    }
  }

  /// BFS Flood Fill — delta-based undo bilan
  /// ═══ PERFORMANCE: Incremental progress tracking ═══
  Future<ui.Image?> fillWithColor(int x, int y, int fillR, int fillG, int fillB) async {
    if (x < 0 || x >= _width || y < 0 || y >= _height) return null;

    final startIdx = y * _width + x;
    if (_boundaryMask[startIdx] == 1) return null;

    final startOffset = startIdx * 4;
    final targetR = _pixels[startOffset];
    final targetG = _pixels[startOffset + 1];
    final targetB = _pixels[startOffset + 2];

    if (_colorMatch(targetR, targetG, targetB, fillR, fillG, fillB)) {
      return null;
    }

    final changedIndices = <int>[];
    final oldColors = <int>[];
    int progressDelta = 0; // ═══ PERFORMANCE: faqat o'zgargan progress

    final visited = Uint8List(_width * _height);
    final queue = Queue<int>();
    const maxFillPixels = 500000;
    int fillCount = 0;

    queue.add(startIdx);
    visited[startIdx] = 1;

    while (queue.isNotEmpty && fillCount < maxFillPixels) {
      final idx = queue.removeFirst();
      fillCount++;

      final offset = idx * 4;
      changedIndices.add(idx);
      oldColors.add(_pixels[offset]);
      oldColors.add(_pixels[offset + 1]);
      oldColors.add(_pixels[offset + 2]);
      oldColors.add(_pixels[offset + 3]);

      // ═══ PERFORMANCE: Incremental progress ═══
      // Faqat ichki maydon piksellarni hisoblash
      if (_backgroundMask[idx] == 0) {
        final wasWhite = _pixels[offset] > 240 &&
            _pixels[offset + 1] > 240 &&
            _pixels[offset + 2] > 240;
        if (wasWhite) {
          progressDelta++; // Yangi bo'yalgan piksel
        }
      }

      _pixels[offset] = fillR;
      _pixels[offset + 1] = fillG;
      _pixels[offset + 2] = fillB;
      _pixels[offset + 3] = 255;

      final px = idx % _width;
      final py = idx ~/ _width;

      if (px > 0) _enqueue(idx - 1, targetR, targetG, targetB, queue, visited);
      if (px < _width - 1) _enqueue(idx + 1, targetR, targetG, targetB, queue, visited);
      if (py > 0) _enqueue(idx - _width, targetR, targetG, targetB, queue, visited);
      if (py < _height - 1) _enqueue(idx + _width, targetR, targetG, targetB, queue, visited);
    }

    if (changedIndices.isNotEmpty) {
      if (_undoStack.length >= _maxUndoSteps) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_FillDelta(
        indices: changedIndices,
        oldColors: Uint8List.fromList(oldColors),
        progressDelta: progressDelta,
      ));

      // ═══ PERFORMANCE: O(1) progress update ═══
      _coloredCount += progressDelta;
      _updateProgress();
    }

    return _createImage();
  }

  void _enqueue(int idx, int targetR, int targetG, int targetB,
      Queue<int> queue, Uint8List visited) {
    if (idx < 0 || idx >= _width * _height) return;
    if (visited[idx] == 1) return;
    if (_boundaryMask[idx] == 1) return;

    final offset = idx * 4;
    final r = _pixels[offset];
    final g = _pixels[offset + 1];
    final b = _pixels[offset + 2];

    if (_colorMatchTolerant(r, g, b, targetR, targetG, targetB)) {
      visited[idx] = 1;
      queue.add(idx);
    }
  }

  bool _colorMatch(int r1, int g1, int b1, int r2, int g2, int b2) {
    return (r1 - r2).abs() < 5 && (g1 - g2).abs() < 5 && (b1 - b2).abs() < 5;
  }

  bool _colorMatchTolerant(int r1, int g1, int b1, int r2, int g2, int b2) {
    return (r1 - r2).abs() < 25 && (g1 - g2).abs() < 25 && (b1 - b2).abs() < 25;
  }

  /// ═══ PERFORMANCE: Undo bilan incremental progress ═══
  Future<ui.Image?> undo() async {
    if (_undoStack.isEmpty) return null;
    final delta = _undoStack.removeLast();

    for (int i = 0; i < delta.indices.length; i++) {
      final offset = delta.indices[i] * 4;
      final colorOffset = i * 4;
      _pixels[offset] = delta.oldColors[colorOffset];
      _pixels[offset + 1] = delta.oldColors[colorOffset + 1];
      _pixels[offset + 2] = delta.oldColors[colorOffset + 2];
      _pixels[offset + 3] = delta.oldColors[colorOffset + 3];
    }

    // ═══ PERFORMANCE: O(1) — delta dan qaytarish ═══
    _coloredCount -= delta.progressDelta;
    if (_coloredCount < 0) _coloredCount = 0;
    _updateProgress();

    return _createImage();
  }

  /// Tozalash
  Future<ui.Image> clearAll() async {
    _undoStack.clear();
    _pixels = Uint8List.fromList(_originalPixels);

    // ═══ PERFORMANCE: Reset to 0 ═══
    _coloredCount = 0;
    _updateProgress();

    return _createImage();
  }

  Future<ui.Image> _createImage() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      _pixels,
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );
    return completer.future;
  }
}

/// Delta — o'zgargan piksellar + progress delta
class _FillDelta {
  final List<int> indices;
  final Uint8List oldColors;
  final int progressDelta; // ═══ PERFORMANCE: undo uchun progress qaytarish

  const _FillDelta({
    required this.indices,
    required this.oldColors,
    required this.progressDelta,
  });
}
