import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import 'story_detail_page.dart';

/// Ertaklar sahifasi — content uploader bazasidan ertaklarni oladi
/// Har bir ertak nomi va tili ko'rsatiladi
/// Bosganda StoryDetailPage ochiladi
class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = '${ApiConstants.baseUrl}/stories';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stories = List<Map<String, dynamic>>.from(data['stories'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Xatolik yuz berdi';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server xatosi: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Serverga ulanib bo\'lmadi';
        _isLoading = false;
      });
    }
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'ertak':
        return '📖';
      case 'masal':
        return '🦊';
      case 'hikoya':
        return '📝';
      case "she'r":
        return '🎵';
      default:
        return '📖';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'ertak':
        return 'Ertak';
      case 'masal':
        return 'Masal';
      case 'hikoya':
        return 'Hikoya';
      case "she'r":
        return "She'r";
      default:
        return 'Ertak';
    }
  }

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'uz':
        return "🇺🇿 O'zbek";
      case 'ru':
        return '🇷🇺 Rus';
      case 'en':
        return '🇬🇧 Ingliz';
      default:
        return "🇺🇿 O'zbek";
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ertak':
        return AppColors.kidPurple;
      case 'masal':
        return AppColors.kidOrange;
      case 'hikoya':
        return AppColors.kidBlue;
      case "she'r":
        return AppColors.kidPink;
      default:
        return AppColors.kidPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: AppColors.storiesGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('📚', style: TextStyle(fontSize: 24.sp)),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ertaklar',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          '${_stories.length} ta ertak mavjud',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadStories,
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 22.sp,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Content ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _stories.isEmpty
                          ? _buildEmpty()
                          : _buildStoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: CircularProgressIndicator(
              color: AppColors.purple,
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Ertaklar yuklanmoqda...',
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('😔', style: TextStyle(fontSize: 36.sp)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Internet aloqangizni tekshirib, qayta urinib ko\'ring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: _loadStories,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: AppColors.storiesGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Qayta urinish',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('📖', style: TextStyle(fontSize: 36.sp)),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Hali ertaklar yo\'q',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ertaklar tez orada qo\'shiladi!',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    return RefreshIndicator(
      onRefresh: _loadStories,
      color: AppColors.purple,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildStoryCard(story);
        },
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final title = story['title'] ?? 'Nomsiz';
    final type = story['type'] ?? 'ertak';
    final language = story['language'] ?? 'uz';
    final storyText = story['storyText'] ?? '';
    final ageMin = story['ageRange']?['min'] ?? 3;
    final ageMax = story['ageRange']?['max'] ?? 12;
    final typeColor = _getTypeColor(type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailPage(
              title: title,
              storyText: storyText,
              type: type,
              language: language,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: typeColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: typeColor.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(
                  _getTypeEmoji(type),
                  style: TextStyle(fontSize: 28.sp),
                ),
              ),
            ),
            SizedBox(width: 14.w),

            // Story info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Turi
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Tili
                      Text(
                        _getLanguageLabel(language),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Yosh chegarasi
                      Text(
                        '👶 $ageMin-$ageMax',
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

            // Arrow
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
