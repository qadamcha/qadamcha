import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Generates jigsaw puzzle piece paths with truly CIRCULAR dome-shaped
/// tabs and blanks using cubic bezier curves.
class JigsawPiecePath {
  static const double _tabFraction = 0.20; // tab height = 20% of piece size
  static const double _nubStart = 0.30; // nub region starts at 30%
  static const double _nubEnd = 0.70; // nub region ends at 70%

  static Path generatePath({
    required double pieceWidth,
    required double pieceHeight,
    required int topEdge,
    required int rightEdge,
    required int bottomEdge,
    required int leftEdge,
  }) {
    final path = Path();
    path.moveTo(0, 0);

    // TOP EDGE (left → right)
    _drawEdge(path,
      startX: 0, startY: 0,
      edgeLen: pieceWidth,
      tabHeight: pieceHeight * _tabFraction,
      edgeType: topEdge,
      isHorizontal: true,
      perpSign: -1.0, // tab goes UP for positive edgeType
    );

    // RIGHT EDGE (top → bottom)
    _drawEdge(path,
      startX: pieceWidth, startY: 0,
      edgeLen: pieceHeight,
      tabHeight: pieceWidth * _tabFraction,
      edgeType: rightEdge,
      isHorizontal: false,
      perpSign: 1.0, // tab goes RIGHT for positive edgeType
    );

    // BOTTOM EDGE (right → left)
    _drawEdge(path,
      startX: pieceWidth, startY: pieceHeight,
      edgeLen: pieceWidth,
      tabHeight: pieceHeight * _tabFraction,
      edgeType: bottomEdge,
      isHorizontal: true,
      perpSign: 1.0, // tab goes DOWN for positive edgeType
      reverse: true,
    );

    // LEFT EDGE (bottom → top)
    _drawEdge(path,
      startX: 0, startY: pieceHeight,
      edgeLen: pieceHeight,
      tabHeight: pieceWidth * _tabFraction,
      edgeType: leftEdge,
      isHorizontal: false,
      perpSign: -1.0, // tab goes LEFT for positive edgeType
      reverse: true,
    );

    path.close();
    return path;
  }

  /// Draw one edge of the puzzle piece.
  /// [perpSign] determines which direction the tab protrudes:
  ///   top=-1(up), right=+1(right), bottom=+1(down), left=-1(left)
  /// [reverse] means the edge goes in negative direction (right→left or bottom→top)
  static void _drawEdge(Path path, {
    required double startX,
    required double startY,
    required double edgeLen,
    required double tabHeight,
    required int edgeType,
    required bool isHorizontal,
    required double perpSign,
    bool reverse = false,
  }) {
    final dir = reverse ? -1.0 : 1.0;
    final endX = isHorizontal ? startX + dir * edgeLen : startX;
    final endY = isHorizontal ? startY : startY + dir * edgeLen;

    if (edgeType == 0) {
      path.lineTo(endX, endY);
      return;
    }

    // Perpendicular offset direction (perpSign * edgeType gives actual direction)
    final pd = perpSign * edgeType.toDouble();

    // Key positions along the edge (fractional)
    final aFrac = _nubStart; // where nub starts
    final bFrac = _nubEnd; // where nub ends
    final midFrac = 0.5;

    if (isHorizontal) {
      final aX = startX + dir * edgeLen * aFrac;
      final bX = startX + dir * edgeLen * bFrac;
      final midX = startX + dir * edgeLen * midFrac;
      final peakY = startY + pd * tabHeight;

      // Dome half-width (from center to neck edge)
      final domeHW = (bX - aX).abs() * 0.5;

      // 1. Straight to nub start
      path.lineTo(aX, startY);

      // 2. LEFT HALF: neck up → circular dome to peak
      //    cp1: straight perpendicular from edge (creates vertical neck)
      //    cp2: at peak height, wide to left (creates dome roundness)
      path.cubicTo(
        aX, startY + pd * tabHeight * 0.6, // cp1: go perpendicular (neck)
        midX - dir * domeHW * 0.9, peakY, // cp2: dome wide left
        midX, peakY, // end: peak center
      );

      // 3. RIGHT HALF: peak → dome → neck down
      path.cubicTo(
        midX + dir * domeHW * 0.9, peakY, // cp1: dome wide right
        bX, startY + pd * tabHeight * 0.6, // cp2: go perpendicular (neck)
        bX, startY, // end: back to edge
      );

      // 4. Straight to edge end
      path.lineTo(endX, endY);
    } else {
      // Vertical edge
      final aY = startY + dir * edgeLen * aFrac;
      final bY = startY + dir * edgeLen * bFrac;
      final midY = startY + dir * edgeLen * midFrac;
      final peakX = startX + pd * tabHeight;

      final domeHH = (bY - aY).abs() * 0.5;

      path.lineTo(startX, aY);

      path.cubicTo(
        startX + pd * tabHeight * 0.6, aY, // cp1: go perpendicular (neck)
        peakX, midY - dir * domeHH * 0.9, // cp2: dome top
        peakX, midY, // end: peak center
      );

      path.cubicTo(
        peakX, midY + dir * domeHH * 0.9, // cp1: dome bottom
        startX + pd * tabHeight * 0.6, bY, // cp2: go perpendicular (neck)
        startX, bY, // end: back to edge
      );

      path.lineTo(endX, endY);
    }
  }
}

/// Clips a widget to a jigsaw piece shape.
class JigsawClipper extends CustomClipper<Path> {
  final double pieceWidth;
  final double pieceHeight;
  final int topEdge;
  final int rightEdge;
  final int bottomEdge;
  final int leftEdge;
  final double tabSize;

  JigsawClipper({
    required this.pieceWidth,
    required this.pieceHeight,
    required this.topEdge,
    required this.rightEdge,
    required this.bottomEdge,
    required this.leftEdge,
    required this.tabSize,
  });

  @override
  Path getClip(Size size) {
    final offsetX = leftEdge == 1 ? tabSize : 0.0;
    final offsetY = topEdge == 1 ? tabSize : 0.0;

    final path = JigsawPiecePath.generatePath(
      pieceWidth: pieceWidth,
      pieceHeight: pieceHeight,
      topEdge: topEdge,
      rightEdge: rightEdge,
      bottomEdge: bottomEdge,
      leftEdge: leftEdge,
    );

    return path.shift(Offset(offsetX, offsetY));
  }

  @override
  bool shouldReclip(covariant JigsawClipper old) =>
      old.pieceWidth != pieceWidth ||
      old.pieceHeight != pieceHeight ||
      old.topEdge != topEdge ||
      old.rightEdge != rightEdge ||
      old.bottomEdge != bottomEdge ||
      old.leftEdge != leftEdge;
}

/// Generates consistent edge configurations for a puzzle grid.
class EdgeConfigGenerator {
  static List<List<Map<String, int>>> generate(int rows, int cols) {
    final rng = Random();
    final config = <List<Map<String, int>>>[];

    for (int r = 0; r < rows; r++) {
      final rowConfig = <Map<String, int>>[];
      for (int c = 0; c < cols; c++) {
        final top = r == 0 ? 0 : -config[r - 1][c]['bottom']!;
        final left = c == 0 ? 0 : -rowConfig[c - 1]['right']!;
        final right = c == cols - 1 ? 0 : (rng.nextBool() ? 1 : -1);
        final bottom = r == rows - 1 ? 0 : (rng.nextBool() ? 1 : -1);

        rowConfig.add({
          'top': top,
          'right': right,
          'bottom': bottom,
          'left': left,
        });
      }
      config.add(rowConfig);
    }
    return config;
  }
}
