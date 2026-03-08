import 'dart:ui';

class PuzzlePiece {
  final int id;
  final int row;
  final int col;
  final int rows;
  final int cols;
  Offset currentOffset;
  Offset correctOffset;
  bool isPlaced;
  // Edge config: 0=flat, 1=tab(out), -1=blank(in)
  final int topEdge;
  final int rightEdge;
  final int bottomEdge;
  final int leftEdge;

  PuzzlePiece({
    required this.id,
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
    required this.currentOffset,
    required this.correctOffset,
    this.isPlaced = false,
    required this.topEdge,
    required this.rightEdge,
    required this.bottomEdge,
    required this.leftEdge,
  });
}

class JigsawLevelData {
  final String id;
  final String name;
  final String imagePath;
  final String category;
  final bool isUnlocked;
  final int stars;

  const JigsawLevelData({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
    this.isUnlocked = false,
    this.stars = 0,
  });

  JigsawLevelData copyWith({bool? isUnlocked, int? stars}) {
    return JigsawLevelData(
      id: id,
      name: name,
      imagePath: imagePath,
      category: category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      stars: stars ?? this.stars,
    );
  }
}

class JigsawCategoryData {
  final String id;
  final String name;
  final String emoji;
  final List<String> gradientColors;
  final List<JigsawLevelData> levels;

  const JigsawCategoryData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradientColors,
    required this.levels,
  });
}
