import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../coloring/screens/coloring_landing_screen.dart';
import '../widgets/bubble_game_card.dart';

/// YouTube Kids 1:1 — O'yinlar sahifasi (Explore tab)
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      _G('🔢', 'Matematika', 'Son va hisob', const Color(0xFF4285F4)),
      _G('🔤', 'Alifbo', 'Harflarni o\'rgan', const Color(0xFFEA4335)),
      _G('🧩', 'Pazl', 'Mantiqiy o\'yin', const Color(0xFF34A853)),
      _G('🎨', 'Ranglar', 'Ranglarni o\'rgan', const Color(0xFFFBBC05)),
      _G('🎵', 'Musiqa', 'Ohang va ritmlar', const Color(0xFF4285F4)),
      _G('🌍', 'Geografiya', 'Dunyoni o\'rgan', const Color(0xFF34A853)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(child: Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18.sp)),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'O\'yinlar',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F0F0F)),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                child: Text(
                  'Ta\'limiy o\'yinlar orqali bilim oling!',
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060)),
                ),
              ),
            ),

            // Game grid (moslashuvchan)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxisCount = screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : (screenWidth > 400 ? 3 : 2));
                  
                  return SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                    ),
                itemCount: games.length,
                itemBuilder: (ctx, i) {
                  final g = games[i];
                  return BubbleGameCard(
                    emoji: g.emoji,
                    title: g.title,
                    subtitle: g.subtitle,
                    color: g.color,
                    onTap: () {
                      if (g.title == 'Ranglar') {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => const ColoringLandingScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('${g.title} tez orada qo\'shiladi! 🚀'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: g.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),

            // Bottom spacing
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
      ),
    );
  }
}

class _G {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _G(this.emoji, this.title, this.subtitle, this.color);
}
