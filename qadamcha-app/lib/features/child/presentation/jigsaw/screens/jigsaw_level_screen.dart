import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/jigsaw_sound_service.dart';
import '../services/jigsaw_storage_service.dart';
import 'jigsaw_game_screen.dart';

class JigsawLevelScreen extends StatefulWidget {
  final JigsawCategoryData category;
  const JigsawLevelScreen({super.key, required this.category});
  @override
  State<JigsawLevelScreen> createState() => _JigsawLevelScreenState();
}

class _JigsawLevelScreenState extends State<JigsawLevelScreen> {
  int _gridSize = 3; // 3x3, 4x4, 5x5

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF60B5FF), Color(0xFF93D1FF), Color(0xFFB8E4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: back button + title + difficulty chips all in one row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      color: const Color(0xFFFF5555),
                      onTap: () {
                        JigsawSoundService().playTap();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.category.emoji} ${widget.category.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4488BB),
                      ),
                    ),
                    const Spacer(),
                    _DifficultyChip(
                      label: '9',
                      gridSize: 3,
                      color: const Color(0xFF4CAF50),
                      isSelected: _gridSize == 3,
                      onTap: () { JigsawSoundService().playTap(); setState(() => _gridSize = 3); },
                    ),
                    const SizedBox(width: 8),
                    _DifficultyChip(
                      label: '16',
                      gridSize: 4,
                      color: const Color(0xFFC49A56),
                      isSelected: _gridSize == 4,
                      onTap: () { JigsawSoundService().playTap(); setState(() => _gridSize = 4); },
                    ),
                    const SizedBox(width: 8),
                    _DifficultyChip(
                      label: '25',
                      gridSize: 5,
                      color: const Color(0xFFE03535),
                      isSelected: _gridSize == 5,
                      onTap: () { JigsawSoundService().playTap(); setState(() => _gridSize = 5); },
                    ),
                  ],
                ),
              ),
              // Horizontal scrolling grid — 2 rows
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: widget.category.levels.length,
                    itemBuilder: (context, index) {
                      final level = widget.category.levels[index];
                      return _LevelCard(
                        level: level,
                        index: index,
                        gridSize: _gridSize,
                        onTap: () {
                          JigsawSoundService().playTap();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JigsawGameScreen(
                                level: level,
                                gridSize: _gridSize,
                              ),
                            ),
                          );
                        },
                      );
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final int gridSize;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _DifficultyChip({
    required this.label,
    required this.gridSize,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini grid preview
            SizedBox(
              width: 22,
              height: 22,
              child: GridView.count(
                crossAxisCount: gridSize,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  gridSize * gridSize,
                  (i) => Container(
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      color: i % 2 == 0
                          ? color
                          : color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(Icons.check_circle, color: color, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final JigsawLevelData level;
  final int index;
  final int gridSize;
  final VoidCallback onTap;
  const _LevelCard({
    required this.level,
    required this.index,
    required this.gridSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: level.isUnlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.9), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                level.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.blue.shade50,
                  child: const Center(
                      child: Text('🧩', style: TextStyle(fontSize: 32))),
                ),
              ),
            ),
            if (!level.isUnlocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 24)),
                ),
              ),
            // Completed badge
            FutureBuilder<bool>(
              future: JigsawStorageService.isLevelCompleted(level.id),
              builder: (ctx, snap) {
                if (snap.data == true) {
                  return Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
