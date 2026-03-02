import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bolalar uchun kreativ bottom nav bar
/// Forest Green tema, katta emoji, yumshoq animatsiya
class YTKidsNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const YTKidsNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 4.h),
          child: Row(
            children: [
              _KidsNavItem(
                emoji: '📺',
                label: 'Multfilmlar',
                activeColor: const Color(0xFF43A047),
                activeBg: const Color(0xFFE8F5E9),
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              SizedBox(width: 12.w),
              _KidsNavItem(
                emoji: '🎮',
                label: 'O\'yinlar',
                activeColor: const Color(0xFF1565C0),
                activeBg: const Color(0xFFE3F2FD),
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KidsNavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final Color activeColor;
  final Color activeBg;
  final bool isSelected;
  final VoidCallback onTap;

  const _KidsNavItem({
    required this.emoji,
    required this.label,
    required this.activeColor,
    required this.activeBg,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 52.h,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: isSelected
                ? Border.all(color: activeColor.withOpacity(0.2), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(fontSize: isSelected ? 28.sp : 24.sp),
                child: Text(emoji),
              ),
              // Label (tanlanganda)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: activeColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
