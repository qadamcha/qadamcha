import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/child_bloc.dart';

/// O'yinlar sahifasi — full_architecture.html dizaynida
/// 2x3 grid: Matematika, Alifbo, Pazl, Ranglar, Musiqa, Geografiya
/// ✅ OPTIMIZED: Tab-level session tracking olib tashlandi
/// (phantom 1-min game_play activity yaratardi — haqiqiy tracking faqat o'yin ochilganda ishlaydi)
class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  late final ChildBloc _childBloc;

  @override
  void initState() {
    super.initState();
    _childBloc = context.read<ChildBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      _Game(emoji: '🔢', title: 'Matematika', subtitle: 'Son va hisob', gradient: AppColors.primaryGradient),
      _Game(emoji: '🔤', title: 'Alifbo', subtitle: 'Harflarni o\'rgan', gradient: AppColors.sunsetGradient),
      _Game(emoji: '🧩', title: 'Pazl', subtitle: 'Mantiqiy o\'yin', gradient: AppColors.gamesGradient),
      _Game(emoji: '🎨', title: 'Ranglar', subtitle: 'Ranglarni o\'rgan', gradient: AppColors.cartoonGradient),
      _Game(emoji: '🎵', title: 'Musiqa', subtitle: 'Ohang va ritmlar', gradient: AppColors.aiGradient),
      _Game(emoji: '🌍', title: 'Geografiya', subtitle: 'Dunyoni o\'rgan', gradient: AppColors.oceanGradient),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    '🎮 O\'yinlar',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Ta\'limiy o\'yinlar orqali bilim oling! 🎯',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Games Grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return _GameCard(game: games[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Game {
  final String emoji;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _Game({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _GameCard extends StatelessWidget {
  final _Game game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.title} tez orada qo\'shiladi! 🚀'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: game.gradient,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: game.gradient.colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(game.emoji, style: TextStyle(fontSize: 32.sp)),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              game.title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              game.subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.85),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
