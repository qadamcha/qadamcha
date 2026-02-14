import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../device/presentation/pages/device_linking_page.dart';
import '../../../auth/presentation/pages/pin_reset_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context),
              SizedBox(height: 8.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    _buildProfileCard(context),
                    SizedBox(height: 24.h),

                    // Umumiy
                    _buildSectionTitle('Umumiy'),
                    SizedBox(height: 10.h),
                    _buildSettingsCard([
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        iconBg: const Color(0xFFFFECCC),
                        iconColor: const Color(0xFFFF9800),
                        title: 'Bildirishnomalar',
                        subtitle: 'Push xabarnomalar',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF2196F3),
                        title: 'Til',
                        subtitle: 'O\'zbek',
                        onTap: () {},
                      ),
                    ]),
                    SizedBox(height: 20.h),

                    // Qurilmalar va Xavfsizlik
                    _buildSectionTitle('Xavfsizlik'),
                    SizedBox(height: 10.h),
                    _buildSettingsCard([
                      _SettingsTile(
                        icon: Icons.devices_rounded,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Ulangan qurilmalar',
                        subtitle: 'Barcha qurilmalarni boshqarish',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeviceLinkingPage()),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        iconBg: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF9C27B0),
                        title: 'PIN kodni o\'zgartirish',
                        subtitle: 'Xavfsizlik sozlamalari',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PinResetPage()),
                        ),
                      ),
                    ]),
                    SizedBox(height: 20.h),

                    // Yordam
                    _buildSectionTitle('Yordam'),
                    SizedBox(height: 10.h),
                    _buildSettingsCard([
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        iconBg: const Color(0xFFF1F8E9),
                        iconColor: const Color(0xFF689F38),
                        title: 'Yordam markazi',
                        subtitle: 'Savollar va javoblar',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xFFE0F7FA),
                        iconColor: const Color(0xFF0097A7),
                        title: 'Maxfiylik siyosati',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        title: 'Foydalanish shartlari',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 28.h),

                    // Logout Button
                    GestureDetector(
                      onTap: () => _showLogoutConfirmation(context),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252).withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: const Color(0xFFFF5252),
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Hisobdan chiqish',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF5252),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // App Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Qadamcha',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary.withOpacity(0.5),
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary.withOpacity(0.35),
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Text(
            'Sozlamalar',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text('\u{1F464}', style: TextStyle(fontSize: 28.sp)),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ota-ona',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '+998 90 *** ** 67',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 18.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontFamily: 'Nunito',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final tile = entry.value;
          final isLast = entry.key == tiles.length - 1;
          return Column(
            children: [
              tile,
              if (!isLast && tile.showDivider)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Divider(
                    height: 1,
                    color: const Color(0xFFF0F0F3),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.logout_rounded,
                    color: const Color(0xFFFF5252),
                    size: 28.sp,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chiqishni xohlaysizmi?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Hisobingizdan chiqish amalga oshiriladi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Center(
                          child: Text(
                            'Bekor',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(LogoutEvent());
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Chiqish',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: iconColor),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
