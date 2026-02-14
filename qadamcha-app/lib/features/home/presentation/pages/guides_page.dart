import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

/// Qo'llanmalar sahifasi — full_architecture.html Bo'lim 3: Ota-ona
/// Tarbiya, Psixologiya, Sog'liq bo'yicha maqolalar
class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> {
  int _selectedCategory = 0;
  final _searchController = TextEditingController();
  
  final _categories = ['Barchasi', 'Tarbiya', 'Psixologiya', 'Sog\'liq'];
  
  final _guides = [
    _Guide(
      emoji: '👶',
      title: 'Bolani ertalab uyg\'otish usullari',
      category: 'Tarbiya',
      readTime: '5 min',
      color: AppColors.kidBlue,
    ),
    _Guide(
      emoji: '🧠',
      title: 'Bolaning xotirasi qanday rivojlanadi?',
      category: 'Psixologiya',
      readTime: '7 min',
      color: AppColors.kidPurple,
    ),
    _Guide(
      emoji: '🥗',
      title: 'Bolalar uchun sog\'lom ovqatlanish',
      category: 'Sog\'liq',
      readTime: '4 min',
      color: AppColors.kidGreen,
    ),
    _Guide(
      emoji: '📖',
      title: 'Kitob o\'qish odatini shakllantirish',
      category: 'Tarbiya',
      readTime: '6 min',
      color: AppColors.kidBlue,
    ),
    _Guide(
      emoji: '😴',
      title: 'Yaxshi uyqu gigiyenasi',
      category: 'Sog\'liq',
      readTime: '5 min',
      color: AppColors.kidGreen,
    ),
    _Guide(
      emoji: '🎯',
      title: 'Bolada mas\'uliyat hissini o\'stirish',
      category: 'Psixologiya',
      readTime: '8 min',
      color: AppColors.kidPurple,
    ),
    _Guide(
      emoji: '🤝',
      title: 'Bola bilan muloqot qilish san\'ati',
      category: 'Tarbiya',
      readTime: '6 min',
      color: AppColors.kidBlue,
    ),
    _Guide(
      emoji: '💪',
      title: 'Bolaning jismoniy faolligi',
      category: 'Sog\'liq',
      readTime: '5 min',
      color: AppColors.kidGreen,
    ),
  ];

  List<_Guide> get _filteredGuides {
    final query = _searchController.text.toLowerCase();
    var list = _guides;
    if (_selectedCategory > 0) {
      list = list.where((g) => g.category == _categories[_selectedCategory]).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((g) => g.title.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Text(
                    '📚',
                    style: TextStyle(fontSize: 28.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Qo\'llanmalar',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Search
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'Nunito',
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: 'Maqola qidirish...',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontFamily: 'Nunito',
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 20.sp,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Categories
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final selected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.primaryGradient : null,
                        color: selected ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16.h),

            // List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _filteredGuides.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final guide = _filteredGuides[index];
                  return _GuideCard(guide: guide);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Guide {
  final String emoji;
  final String title;
  final String category;
  final String readTime;
  final Color color;

  const _Guide({
    required this.emoji,
    required this.title,
    required this.category,
    required this.readTime,
    required this.color,
  });
}

class _GuideCard extends StatelessWidget {
  final _Guide guide;

  const _GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: guide.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(guide.emoji, style: TextStyle(fontSize: 28.sp)),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: guide.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        guide.category,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: guide.color,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '📖 ${guide.readTime}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}
