import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../coloring/screens/coloring_landing_screen.dart';
import '../jigsaw/screens/jigsaw_splash_screen.dart';

/// O'yinlar sahifasi — faqat ikonlar, toza dizayn
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ HEADER ═══
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34A853), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O\'yinlar',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Ta\'limiy o\'yinlar orqali bilim oling!',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ═══ O'YINLAR ═══
            SizedBox(height: 20.h),

            // ═══ O'YINLAR ═══
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Puzzle
                  _GameIcon(
                    imagePath: 'assets/images/puzzle_game_card.png',
                    onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JigsawSplashScreen(),
                      ),
                    ).then((_) {
                      // O'yindan qaytganda counterni oshirish
                      LocalMonitoringService.instance.addGamePlayed();
                      LocalMonitoringService.instance.addActivityLog(
                        activityType: 'game_play',
                        contentTitle: 'Jigsaw Puzzle',
                        durationMinutes: 1,
                      );
                    });
                  },
                  ),
                  SizedBox(width: 20.w),
                  // Ranglar
                  _GameIcon(
                    imagePath: 'assets/images/coloring_logo.png',
                    onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ColoringLandingScreen(),
                      ),
                    ).then((_) {
                      // O'yindan qaytganda counterni oshirish
                      LocalMonitoringService.instance.addGamePlayed();
                      LocalMonitoringService.instance.addActivityLog(
                        activityType: 'game_play',
                        contentTitle: 'Ranglar o\'yini',
                        durationMinutes: 1,
                      );
                    });
                  },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toza o'yin ikon widgeti — faqat rasm, bosish animatsiyasi
class _GameIcon extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _GameIcon({
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_GameIcon> createState() => _GameIconState();
}

class _GameIconState extends State<_GameIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.38;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
