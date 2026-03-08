import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import 'story_detail_page.dart';

/// Ertaklar sahifasi — filtr paneli bilan (content_page.dart uslubida)
/// Barchasi / Yangi tablar + Yosh, Til, Tur bo'yicha filtr
class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  List<Map<String, dynamic>> _allStories = [];
  List<Map<String, dynamic>> _filteredStories = [];
  bool _isLoading = true;
  String? _error;

  int _selectedTab = 0;
  final _tabs = ['Barchasi', 'Yangi'];

  // Filter state
  String? _selectedAge;
  String? _selectedLanguage;
  String? _selectedType;

  final _ages = ['0-3 yosh', '3-6 yosh', '6-9 yosh', '9-12 yosh'];
  final _languages = ["O'zbekcha", 'Ruscha', 'Inglizcha'];
  final _types = ['Jahon', "O'zbek", 'Islomiy'];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = '${ApiConstants.baseUrl}/stories';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allStories = List<Map<String, dynamic>>.from(data['stories'] ?? []);
            _applyFilters();
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
      if (!mounted) return;
      setState(() {
        _error = 'Serverga ulanib bo\'lmadi';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_allStories);

    // Tab filter
    if (_selectedTab == 1) {
      // "Yangi" — oxirgi 2 hafta ichida qo'shilganlar
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      result = result.where((s) {
        final created = DateTime.tryParse(s['createdAt'] ?? '');
        return created != null && created.isAfter(twoWeeksAgo);
      }).toList();
    }

    // Type filter
    if (_selectedType != null) {
      String typeValue;
      switch (_selectedType) {
        case 'Jahon':
          typeValue = 'jahon';
          break;
        case "O'zbek":
          typeValue = 'ozbek';
          break;
        case 'Islomiy':
          typeValue = 'islomiy';
          break;
        default:
          typeValue = '';
      }
      if (typeValue.isNotEmpty) {
        result = result.where((s) => s['type'] == typeValue).toList();
      }
    }

    // Language filter
    if (_selectedLanguage != null) {
      String langValue;
      switch (_selectedLanguage) {
        case "O'zbekcha":
          langValue = 'uz';
          break;
        case 'Ruscha':
          langValue = 'ru';
          break;
        case 'Inglizcha':
          langValue = 'en';
          break;
        default:
          langValue = '';
      }
      if (langValue.isNotEmpty) {
        result = result.where((s) => s['language'] == langValue).toList();
      }
    }

    // Age filter
    if (_selectedAge != null) {
      final match = RegExp(r'(\d+)-(\d+)').firstMatch(_selectedAge!);
      if (match != null) {
        final minAge = int.parse(match.group(1)!);
        final maxAge = int.parse(match.group(2)!);
        result = result.where((s) {
          final sMin = s['ageRange']?['min'] ?? 0;
          final sMax = s['ageRange']?['max'] ?? 18;
          return sMin <= maxAge && sMax >= minAge;
        }).toList();
      }
    }

    _filteredStories = result;
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'jahon':
        return Icons.public_rounded;
      case 'ozbek':
        return Icons.flag_rounded;
      case 'islomiy':
        return Icons.auto_stories_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'jahon':
        return 'Jahon';
      case 'ozbek':
        return "O'zbek";
      case 'islomiy':
        return 'Islomiy';
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
      case 'jahon':
        return AppColors.primary;
      case 'ozbek':
        return AppColors.primaryDark;
      case 'islomiy':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.primary;
    }
  }

  bool get _hasActiveFilters =>
      _selectedAge != null || _selectedLanguage != null || _selectedType != null;

  int get _activeFilterCount =>
      (_selectedAge != null ? 1 : 0) +
      (_selectedLanguage != null ? 1 : 0) +
      (_selectedType != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Icon(Icons.auto_stories_rounded, size: 20.sp, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Ertaklar',
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

            // ─── Tabs + Filter Button ────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  // Tabs
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final selected = _selectedTab == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = index;
                                _applyFilters();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 22.w),
                              decoration: BoxDecoration(
                                gradient: selected ? AppColors.primaryGradient : null,
                                color: selected ? null : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _tabs[index],
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
                  ),
                  SizedBox(width: 8.w),
                  // Filter button
                  GestureDetector(
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                        border: _hasActiveFilters
                            ? Border.all(color: AppColors.primary.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18.sp,
                            color: _hasActiveFilters
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Filtr',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          if (_activeFilterCount > 0) ...[
                            SizedBox(width: 4.w),
                            Container(
                              width: 18.w,
                              height: 18.w,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_activeFilterCount',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // ─── Stats bar ───────────────────────────────────────────
            if (!_isLoading && _error == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Text(
                      '${_filteredStories.length} ta ertak',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      Text(
                        ' (${_allStories.length} dan)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary.withOpacity(0.6),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            SizedBox(height: 8.h),

            // ─── Content ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _filteredStories.isEmpty
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
              color: AppColors.primary,
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
                child: Icon(Icons.sentiment_dissatisfied_rounded, size: 36.sp, color: AppColors.error),
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
                  gradient: AppColors.primaryGradient,
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
              child: Icon(Icons.menu_book_rounded, size: 36.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _hasActiveFilters ? 'Filtrga mos ertak topilmadi' : 'Hali ertaklar yo\'q',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _hasActiveFilters ? 'Filtrni o\'zgartirib ko\'ring' : 'Ertaklar tez orada qo\'shiladi!',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
          if (_hasActiveFilters) ...[
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAge = null;
                  _selectedLanguage = null;
                  _selectedType = null;
                  _selectedTab = 0;
                  _applyFilters();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Filtrni tozalash',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    return RefreshIndicator(
      onRefresh: _loadStories,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: _filteredStories.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final story = _filteredStories[index];
          return _buildStoryCard(story);
        },
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final title = story['title'] ?? 'Nomsiz';
    final type = story['type'] ?? 'ozbek';
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
                child: Icon(
                  _getTypeIcon(type),
                  size: 28.sp,
                  color: typeColor,
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
                      fontSize: 18.sp,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.child_care_rounded, size: 14.sp, color: AppColors.textSecondary),
                            SizedBox(width: 2.w),
                            Text(
                              '$ageMin-$ageMax',
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

  // ─── Filter Bottom Sheet ──────────────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    String? tempAge = _selectedAge;
    String? tempLang = _selectedLanguage;
    String? tempType = _selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\ud83c\udf9b\ufe0f Filtr',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      if (tempAge != null || tempLang != null || tempType != null)
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              tempAge = null;
                              tempLang = null;
                              tempType = null;
                            });
                          },
                          child: Text(
                            'Tozalash',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Type filter
                  _buildFilterSection(
                    '📚 Tur',
                    _types,
                    tempType,
                    (val) => setSheetState(() => tempType = tempType == val ? null : val),
                  ),

                  SizedBox(height: 16.h),

                  // Age filter
                  _buildFilterSection(
                    '👶 Yosh',
                    _ages,
                    tempAge,
                    (val) => setSheetState(() => tempAge = tempAge == val ? null : val),
                  ),

                  SizedBox(height: 16.h),

                  // Language filter
                  _buildFilterSection(
                    '🌐 Til',
                    _languages,
                    tempLang,
                    (val) => setSheetState(() => tempLang = tempLang == val ? null : val),
                  ),

                  SizedBox(height: 24.h),

                  // Apply button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAge = tempAge;
                        _selectedLanguage = tempLang;
                        _selectedType = tempType;
                        _applyFilters();
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Qo\'llash',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String> onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onTap(opt),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
