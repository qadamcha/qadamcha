import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // App logo & version card
                    _buildAppCard(),
                    SizedBox(height: 16.h),

                    // Mission
                    _buildMissionCard(),
                    SizedBox(height: 16.h),

                    // Features
                    _buildFeaturesCard(),
                    SizedBox(height: 16.h),

                    // Team
                    _buildTeamCard(),
                    SizedBox(height: 16.h),


                    // Social links
                    _buildSocialLinks(),
                    SizedBox(height: 16.h),

                    // Copyright
                    _buildCopyright(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Ilova haqida ℹ️',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard() {
    final version = _packageInfo?.version ?? '...';
    final buildNumber = _packageInfo?.buildNumber ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A9F).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 56.w,
                height: 56.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Qadamcha',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Nunito',
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Bolalar nazorati va ta\'lim ilovasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 16.h),

          // Version badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Versiya $version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return _buildCard(
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFEF4444),
      title: 'Bizning maqsadimiz',
      child: Text(
        'Qadamcha — farzandlaringiz uchun raqamli dunyoni xavfsiz va '
        'foydali qilish maqsadida yaratilgan. Biz ota-onalarga '
        'bolalarining raqamli vaqtini oqilona boshqarish, bo\'yash '
        'o\'yinlari va AI yordamchi orqali ijodiy rivojlantirish, '
        'ta\'limiy videolar va hikoyalar bilan bilim berish imkonini '
        'yaratamiz.\n\n'
        'Har bir bola xavfsiz, ta\'limiy va qiziqarli raqamli '
        'muhitga loyiq.',
        style: TextStyle(
          fontSize: 13.sp,
          color: const Color(0xFF4B5563),
          fontFamily: 'Nunito',
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = [
      _FeatureItem(
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF2D6A9F),
        title: 'Monitoring',
        desc: 'Bola qurilmasidagi faoliyatni real-time kuzatish',
      ),
      _FeatureItem(
        icon: Icons.palette_rounded,
        color: const Color(0xFFFF6D00),
        title: 'Bo\'yash o\'yini',
        desc: '70+ rasm, 5 kategoriya — ijodiy mashq',
      ),
      _FeatureItem(
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF7C4DFF),
        title: 'Bilimdon AI',
        desc: 'Bolalar uchun sun\'iy intellekt yordamchisi',
      ),
      _FeatureItem(
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF22C55E),
        title: 'Ta\'limiy kontent',
        desc: 'Video darslar va hikoyalar — yoshga mos',
      ),
      _FeatureItem(
        icon: Icons.timer_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Vaqt boshqaruvi',
        desc: 'Ekran vaqtini belgilash va nazorat qilish',
      ),
      _FeatureItem(
        icon: Icons.lock_rounded,
        color: const Color(0xFFEF4444),
        title: 'Xavfsizlik',
        desc: 'PIN kod va shifrlash bilan himoyalangan',
      ),
    ];

    return _buildCard(
      icon: Icons.star_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'Asosiy imkoniyatlar',
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Icon(f.icon, color: f.color, size: 18.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        f.desc,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamCard() {
    return _buildCard(
      icon: Icons.groups_rounded,
      iconColor: const Color(0xFF7C4DFF),
      title: 'Jamoa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qadamcha O\'zbekistondagi iste\'dodli dasturchilar jamoasi '
            'tomonidan yaratilgan. Biz texnologiya va ta\'limni birlashtirgan '
            'holda oilalar uchun eng yaxshi yechimlarni yaratishga '
            'intilamiz.',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF4B5563),
              fontFamily: 'Nunito',
              height: 1.6,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Text('🇺🇿', style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Made in Uzbekistan',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C4DFF),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      Text(
                        'O\'zbekiston, Toshkent',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSocialLinks() {
    return _buildCard(
      icon: Icons.language_rounded,
      iconColor: const Color(0xFF2D6A9F),
      title: 'Biz bilan bog\'laning',
      child: Column(
        children: [
          _buildSocialRow(
            icon: Icons.language_rounded,
            label: 'Veb-sayt',
            value: 'qadamcha.uz',
            onTap: () => _launchUrl('https://qadamcha.uz'),
          ),
          _buildSocialRow(
            icon: Icons.send_rounded,
            label: 'Telegram',
            value: '@qadamcha_uz',
            onTap: () => _launchUrl('https://t.me/qadamcha_uz'),
          ),
          _buildSocialRow(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            value: '@qadamcha.uz',
            onTap: () =>
                _launchUrl('https://instagram.com/qadamcha.uz'),
          ),
          _buildSocialRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'support@qadamcha.uz',
            onTap: () => _launchUrl('mailto:support@qadamcha.uz'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A9F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(icon,
                  color: const Color(0xFF2D6A9F), size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9CA3AF),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D6A9F),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: const Color(0xFF9CA3AF),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            '© $year Qadamcha',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Barcha huquqlar himoyalangan',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF9CA3AF),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Farzandlaringiz uchun mehr bilan yaratilgan',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}


