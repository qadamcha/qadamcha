import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/guides_data.dart';

/// Maqola tafsiloti sahifasi
class GuideDetailPage extends StatelessWidget {
  final GuideArticle guide;
  const GuideDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Hero header — rasm to'liq qoplab turadi
          SliverAppBar(
            expandedHeight: 240.h,
            pinned: true,
            backgroundColor: guide.color,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Rasm to'liq qoplab turadi
                  Image.asset(
                    guide.heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [guide.color, guide.color.withOpacity(0.7)],
                        ),
                      ),
                      child: Center(child: Text(guide.emoji, style: TextStyle(fontSize: 64.sp))),
                    ),
                  ),
                  // Pastki gradient (matn o'qilishi uchun)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                guide.title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
            ),
          ),

          // Kontent
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sarlavha
                  Text(
                    '${guide.emoji} ${guide.title}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Qisqacha tavsif
                  Text(
                    guide.summary,
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Bo'limlar
                  ...guide.sections.map((s) => _buildSection(s)),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(GuideSection section) {
    switch (section.type) {
      case 'text':
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Text(
            section.content ?? '',
            style: TextStyle(
              fontSize: 17.sp,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
              height: 1.6,
            ),
          ),
        );
      case 'heading':
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
          child: Text(
            section.title ?? '',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
        );
      case 'list':
        return _buildList(section);
      case 'table':
        return _buildTable(section);
      case 'fact':
        return _buildInfoBox(section, const Color(0xFF2D6A9F), Icons.science_rounded);
      case 'tip':
        return _buildInfoBox(section, const Color(0xFF22C55E), Icons.lightbulb_rounded);
      case 'warning':
        return _buildInfoBox(section, const Color(0xFFEF4444), Icons.warning_rounded);
      case 'image':
        return _buildImage(section);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildList(GuideSection section) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (section.items ?? []).map((item) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(item, style: TextStyle(
              fontSize: 16.sp, color: AppColors.textPrimary,
              fontFamily: 'Nunito', height: 1.5,
            )),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTable(GuideSection section) {
    final headers = section.tableHeaders ?? [];
    final data = section.tableData ?? [];
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Jadval sarlavhasi
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: guide.color.withOpacity(0.08),
              ),
              child: Row(
                children: headers.asMap().entries.map((e) => Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12.sp, fontWeight: FontWeight.w700,
                      color: guide.color, fontFamily: 'Nunito',
                    ),
                    textAlign: e.key == 0 ? TextAlign.left : TextAlign.center,
                  ),
                )).toList(),
              ),
            ),
            // Jadval qatorlari
            ...data.asMap().entries.map((rowEntry) => Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: rowEntry.key.isEven ? Colors.white : const Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5)),
              ),
              child: Row(
                children: rowEntry.value.asMap().entries.map((cellEntry) => Expanded(
                  child: Text(
                    cellEntry.value,
                    style: TextStyle(
                      fontSize: 12.sp, color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: cellEntry.key == 0 ? TextAlign.left : TextAlign.center,
                  ),
                )).toList(),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(GuideSection section, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w, height: 40.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(child: Icon(icon, size: 22.sp, color: color)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${section.emoji ?? ''} ${section.title ?? ''}',
                    style: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w700,
                      color: color, fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    section.content ?? '',
                    style: TextStyle(
                      fontSize: 15.sp, color: AppColors.textPrimary,
                      fontFamily: 'Nunito', height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(GuideSection section) {
    if (section.imagePath == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.asset(
          section.imagePath!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
