import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// Flood Fill Engine v4 — Production-grade
///
/// Advanced image processing pipeline:
/// 1. Grayscale conversion
/// 2. Otsu's automatic threshold (eng optimal qora/oq ajratish)
/// 3. Morphological dilation (qora chiziqlarni qalinlashtirish — teshiklarni yopish)
/// 4. Clean BFS flood fill with boundary mask
class FloodFillEngine {
  late Uint8List _pixels;
  late int _width;
  late int _height;
  late Uint8List _originalPixels;

  /// Binary mask: 1 = chegara (qora), 0 = bo'yash mumkin (oq)
  late Uint8List _boundaryMask;

  /// Background mask: 1 = tashqi fon (progress hisobga kiritilmaydi)
  late Uint8List _backgroundMask;

  /// Delta-based undo stack — faqat o'zgargan piksellarni saqlaydi
  /// Xotira optimizatsiyasi: to'liq nusxa (~16MB) o'rniga delta (~200KB)
  final List<_FillDelta> _undoStack = [];
  static const int _maxUndoSteps = 15;

  bool get canUndo => _undoStack.isNotEmpty;
  int get width => _width;
  int get height => _height;

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

    // ═══ BACKGROUND DETECTION ═══
    // Rasm chekkasidagi oq zonalarni "fon" deb belgilash
    _detectBackground();

    _originalPixels = Uint8List.fromList(_pixels);
    
    // Dastlabki dekod qilingan original rasmni xotiradan tozalash (Memory leak oldini oladi)
    image.dispose();
    codec.dispose();
    
    return _createImage();
  }

  /// Advanced pre-processing: Grayscale → Otsu → Dilation → Binary
  void _advancedPreProcess() {
    final totalPixels = _width * _height;

    // ── Step 1: Grayscale ga aylantirish ──
    final grayscale = Uint8List(totalPixels);
    for (int i = 0; i < totalPixels; i++) {
      final offset = i * 4;
      final r = _pixels[offset];
      final g = _pixels[offset + 1];
      final b = _pixels[offset + 2];
      final a = _pixels[offset + 3];

      if (a < 128) {
        grayscale[i] = 255; // Transparent = oq
      } else {
        // Weighted grayscale (human perception)
        grayscale[i] = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
      }
    }

    // ── Step 2: Otsu's threshold (avtomatik eng yaxshi threshold topish) ──
    final threshold = _otsuThreshold(grayscale);

    // ── Step 3: Binary mask yaratish ──
    _boundaryMask = Uint8List(totalPixels);
    for (int i = 0; i < totalPixels; i++) {
      _boundaryMask[i] = grayscale[i] < threshold ? 1 : 0; // 1=qora, 0=oq
    }

    // ── Step 4: Morphological dilation (qora chiziqlarni 1px qalinlashtirish) ──
    // Bu kichik teshiklarni yopadi — rang boshqa tomonga o'tmaydi
    _dilateBoundary();

    // ── Step 5: Piksellarni sof qora/oq ga yozish ──
    for (int i = 0; i < totalPixels; i++) {
      final offset = i * 4;
      if (_boundaryMask[i] == 1) {
        // Qora (chegara)
        _pixels[offset] = 0;
        _pixels[offset + 1] = 0;
        _pixels[offset + 2] = 0;
        _pixels[offset + 3] = 255;
      } else {
        // Oq (bo'yash mumkin)
        _pixels[offset] = 255;
        _pixels[offset + 1] = 255;
        _pixels[offset + 2] = 255;
        _pixels[offset + 3] = 255;
      }
    }
  }

  /// Otsu's method — histogram-based optimal threshold
  /// Rasmni eng yaxshi qora/oq ga ajratadigan thresholdni avtomatik topadi
  int _otsuThreshold(Uint8List grayscale) {
    // Histogram yaratish (0-255)
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
    int bestThreshold = 128; // fallback

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

    // Coloring page uchun threshold ni biroz yuqoriroq qilish
    // (kulrang piksellarni ham qora deb olish — chegara kuchayadi)
    return math.min(bestThreshold + 30, 240);
  }

  /// Morphological dilation — qora piksellarni 1px kengaytirish
  /// Bu kichik oraliqlarni (1-2px gap) yopadi
  void _dilateBoundary() {
    final totalPixels = _width * _height;
    final dilated = Uint8List.fromList(_boundaryMask);

    for (int y = 1; y < _height - 1; y++) {
      for (int x = 1; x < _width - 1; x++) {
        final idx = y * _width + x;
        if (_boundaryMask[idx] == 1) {
          // Qo'shnilarni ham qora qilish (3x3 kernel, faqat 4 yo'nalishli cross)
          dilated[idx - 1] = 1;         // chap
          dilated[idx + 1] = 1;         // o'ng
          dilated[idx - _width] = 1;    // yuqori
          dilated[idx + _width] = 1;    // past
        }
      }
    }

    // Dilated natijani qaytarish
    for (int i = 0; i < totalPixels; i++) {
      _boundaryMask[i] = dilated[i];
    }
  }

  /// Rasm chekkasidan BFS qilib tashqi fonni aniqlash
  /// Chekkaga tegib turgan oq piksellar va ulardan chegara (qora) kesmasdan
  /// yetib boladigan barcha piksellar = BACKGROUND
  void _detectBackground() {
    final totalPixels = _width * _height;
    _backgroundMask = Uint8List(totalPixels); // 0 = ichki, 1 = fon

    final visited = Uint8List(totalPixels);
    final queue = Queue<int>();

    // Rasm 4 ta chekkasidagi barcha oq (non-boundary) piksellarni navbatga qo'shish
    for (int x = 0; x < _width; x++) {
      // Yuqori chekka
      final topIdx = x;
      if (_boundaryMask[topIdx] == 0 && visited[topIdx] == 0) {
        visited[topIdx] = 1;
        queue.add(topIdx);
      }
      // Pastki chekka
      final bottomIdx = (_height - 1) * _width + x;
      if (_boundaryMask[bottomIdx] == 0 && visited[bottomIdx] == 0) {
        visited[bottomIdx] = 1;
        queue.add(bottomIdx);
      }
    }
    for (int y = 0; y < _height; y++) {
      // Chap chekka
      final leftIdx = y * _width;
      if (_boundaryMask[leftIdx] == 0 && visited[leftIdx] == 0) {
        visited[leftIdx] = 1;
        queue.add(leftIdx);
      }
      // O'ng chekka
      final rightIdx = y * _width + (_width - 1);
      if (_boundaryMask[rightIdx] == 0 && visited[rightIdx] == 0) {
        visited[rightIdx] = 1;
        queue.add(rightIdx);
      }
    }

    // BFS — chekkadan chegara kesmasdan yetib bolinadigan barcha piksellar = fon
    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      _backgroundMask[idx] = 1;

      final px = idx % _width;
      final py = idx ~/ _width;

      // 4 yo'nalish
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

  /// BFS Flood Fill — piksel-piksel to'ldirish (delta-based undo bilan)
  Future<ui.Image?> fillWithColor(int x, int y, int fillR, int fillG, int fillB) async {
    if (x < 0 || x >= _width || y < 0 || y >= _height) return null;

    final startIdx = y * _width + x;

    // Chegaraga bosilgan bo'lsa — hech narsa qilmaymiz
    if (_boundaryMask[startIdx] == 1) return null;

    // Target rangni olish
    final startOffset = startIdx * 4;
    final targetR = _pixels[startOffset];
    final targetG = _pixels[startOffset + 1];
    final targetB = _pixels[startOffset + 2];

    // Agar bir xil rang bo'lsa — hech narsa qilmaymiz
    if (_colorMatch(targetR, targetG, targetB, fillR, fillG, fillB)) {
      return null;
    }

    // Delta uchun o'zgargan piksellarni yig'ish
    final changedIndices = <int>[];
    final oldColors = <int>[]; // R, G, B, A ketma-ket

    // BFS — max 500K piksel (katta maydonlar uchun himoya)
    final visited = Uint8List(_width * _height);
    final queue = Queue<int>();
    const maxFillPixels = 500000;
    int fillCount = 0;

    queue.add(startIdx);
    visited[startIdx] = 1;

    while (queue.isNotEmpty && fillCount < maxFillPixels) {
      final idx = queue.removeFirst();
      fillCount++;

      // Eski rangni delta uchun saqlash
      final offset = idx * 4;
      changedIndices.add(idx);
      oldColors.add(_pixels[offset]);
      oldColors.add(_pixels[offset + 1]);
      oldColors.add(_pixels[offset + 2]);
      oldColors.add(_pixels[offset + 3]);

      // Bo'yash
      _pixels[offset] = fillR;
      _pixels[offset + 1] = fillG;
      _pixels[offset + 2] = fillB;
      _pixels[offset + 3] = 255;

      // 4 qo'shni
      final px = idx % _width;
      final py = idx ~/ _width;

      if (px > 0) _enqueue(idx - 1, targetR, targetG, targetB, queue, visited);
      if (px < _width - 1) _enqueue(idx + 1, targetR, targetG, targetB, queue, visited);
      if (py > 0) _enqueue(idx - _width, targetR, targetG, targetB, queue, visited);
      if (py < _height - 1) _enqueue(idx + _width, targetR, targetG, targetB, queue, visited);
    }

    // Delta ni undo stack ga saqlash
    if (changedIndices.isNotEmpty) {
      if (_undoStack.length >= _maxUndoSteps) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_FillDelta(
        indices: changedIndices,
        oldColors: Uint8List.fromList(oldColors),
      ));
    }

    return _createImage();
  }

  void _enqueue(int idx, int targetR, int targetG, int targetB,
      Queue<int> queue, Uint8List visited) {
    if (idx < 0 || idx >= _width * _height) return; // bounds check
    if (visited[idx] == 1) return;
    if (_boundaryMask[idx] == 1) return;

    final offset = idx * 4;
    final r = _pixels[offset];
    final g = _pixels[offset + 1];
    final b = _pixels[offset + 2];

    // Target rangga o'xshash bo'lsa — navbatga qo'shish
    if (_colorMatchTolerant(r, g, b, targetR, targetG, targetB)) {
      visited[idx] = 1;
      queue.add(idx);
    }
  }

  /// Aniq rang solishtiruv (5 px tolerance)
  bool _colorMatch(int r1, int g1, int b1, int r2, int g2, int b2) {
    return (r1 - r2).abs() < 5 && (g1 - g2).abs() < 5 && (b1 - b2).abs() < 5;
  }

  /// Tolerant rang solishtiruv (flood fill uchun)
  bool _colorMatchTolerant(int r1, int g1, int b1, int r2, int g2, int b2) {
    return (r1 - r2).abs() < 25 && (g1 - g2).abs() < 25 && (b1 - b2).abs() < 25;
  }

  /// Undo — delta dan faqat o'zgargan piksellarni tiklash
  Future<ui.Image?> undo() async {
    if (_undoStack.isEmpty) return null;
    final delta = _undoStack.removeLast();

    // O'zgargan piksellarning eski ranglarini qayta yozish
    for (int i = 0; i < delta.indices.length; i++) {
      final offset = delta.indices[i] * 4;
      final colorOffset = i * 4;
      _pixels[offset] = delta.oldColors[colorOffset];
      _pixels[offset + 1] = delta.oldColors[colorOffset + 1];
      _pixels[offset + 2] = delta.oldColors[colorOffset + 2];
      _pixels[offset + 3] = delta.oldColors[colorOffset + 3];
    }

    return _createImage();
  }

  /// Tozalash
  Future<ui.Image> clearAll() async {
    _undoStack.clear();
    _pixels = Uint8List.fromList(_originalPixels);
    return _createImage();
  }

  /// Bo'yalganlik tekshirish
  bool isCompleted() {
    return progress >= 0.99; // 99% ni tugagan deb hisoblaymiz
  }

  /// Bo'yash progressi (0.0 dan 1.0 gacha)
  /// Faqat chegaralar ICHIDAGI maydonlarni hisoblaydi.
  /// Tashqi fon (background) hisobga kiritilmaydi.
  double get progress {
    if (_width == 0 || _height == 0) return 0.0;
    final totalPixels = _width * _height;
    int paintable = 0;
    int colored = 0;

    for (int i = 0; i < totalPixels; i++) {
      // Faqat: chegara EMAS + fon EMAS = ichki maydon
      if (_boundaryMask[i] == 0 && _backgroundMask[i] == 0) {
        paintable++;
        final offset = i * 4;
        if (_pixels[offset] > 240 &&
            _pixels[offset + 1] > 240 &&
            _pixels[offset + 2] > 240) {
          // Oq piksel (bo'yalmagan)
        } else {
          colored++; // Bo'yalgan
        }
      }
    }
    
    if (paintable == 0) return 1.0;
    return colored / paintable;
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

/// Delta — faqat o'zgargan piksellarni saqlash (xotira tejash)
/// To'liq nusxa: ~16MB (2000×2000 rasm)
/// Delta: ~200KB-2MB (5K-50K piksel)
class _FillDelta {
  /// O'zgargan piksellarning flat indekslari
  final List<int> indices;

  /// Eski ranglar: R, G, B, A ketma-ket (indices.length × 4 bayt)
  final Uint8List oldColors;

  const _FillDelta({
    required this.indices,
    required this.oldColors,
  });
}
