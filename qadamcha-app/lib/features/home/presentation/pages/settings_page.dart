import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../device/presentation/bloc/device_bloc.dart';
import '../../../device/presentation/pages/device_linking_page.dart';
import 'privacy_policy_page.dart';
import 'help_center_page.dart';
import 'about_app_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // Qurilmalar sonini yuklash
    context.read<DeviceBloc>().add(LoadDevicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
                    'Sozlamalar ⚙️',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF2D6A9F),
                onRefresh: () async {
                  // Profil, qurilmalar va obunani yangilash
                  context.read<AuthBloc>().add(CheckAuthStatusEvent());
                  context.read<DeviceBloc>().add(LoadDevicesEvent());
                  context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card — real ma'lumotlar
                    _buildProfileCard(context, user),
                    SizedBox(height: 12.h),

                    // Subscription Info
                    _buildSubscriptionInfo(context),
                    SizedBox(height: 12.h),

                    // Umumiy Section
                    _buildSectionTitle('Umumiy'),
                    SizedBox(height: 8.h),
                    _buildSettingsCard([
                      _SettingsRow(
                        emoji: '👤',
                        bgColor: const Color(0xFF2D6A9F).withOpacity(0.08),
                        title: 'Profilni tahrirlash',
                        trailing: _arrowIcon(),
                        onTap: () => _showEditProfileDialog(context, user?.name ?? ''),
                      ),
                      BlocBuilder<DeviceBloc, DeviceState>(
                        builder: (context, deviceState) {
                          final deviceCount = deviceState.devices.length;
                          final maxDevices = deviceState.maxDevices;
                          return _SettingsRow(
                            emoji: '📱',
                            bgColor: const Color(0xFF7C4DFF).withOpacity(0.08),
                            title: 'Qurilmalarni boshqarish',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A9F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '$deviceCount/$maxDevices',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D6A9F),
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                _arrowIcon(),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DeviceLinkingPage()),
                            ),
                          );
                        },
                      ),
                      _SettingsRow(
                        emoji: '🔒',
                        bgColor: const Color(0xFF22C55E).withOpacity(0.08),
                        title: 'PIN kodni o\'zgartirish',
                        trailing: _arrowIcon(),
                        onTap: () => _showChangePinDialog(context, user?.phone ?? ''),
                      ),
                      _SettingsRow(
                        emoji: '🔔',
                        bgColor: const Color(0xFFFF6D00).withOpacity(0.08),
                        title: 'Bildirishnomalar',
                        trailing: _buildSwitch(_notificationsEnabled),
                        onTap: () {
                          setState(() {
                            _notificationsEnabled = !_notificationsEnabled;
                          });
                        },
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 12.h),

                    // Boshqa Section
                    _buildSectionTitle('Boshqa'),
                    SizedBox(height: 8.h),
                    _buildSettingsCard([
                      _SettingsRow(
                        emoji: '🛡️',
                        bgColor: const Color(0xFF6B7280).withOpacity(0.08),
                        title: 'Maxfiylik siyosati',
                        trailing: _arrowIcon(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                        ),
                      ),
                      _SettingsRow(
                        emoji: '❓',
                        bgColor: const Color(0xFF6B7280).withOpacity(0.08),
                        title: 'Yordam markazi',
                        trailing: _arrowIcon(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                        ),
                      ),
                      _SettingsRow(
                        emoji: 'ℹ️',
                        bgColor: const Color(0xFF6B7280).withOpacity(0.08),
                        title: 'Ilova haqida',
                        trailing: _arrowIcon(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutAppPage()),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 16.h),

                    // Logout Button
                    _buildLogoutButton(context),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    final userName = user?.name ?? 'Foydalanuvchi';
    final userPhone = user?.phone ?? '';

    // Ismning birinchi harfini avatar sifatida olish
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D6A9F).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatPhone(userPhone),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              if (state.isPremium) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.1),
                        const Color(0xFFFBBF24).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('👑', style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 3.w),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// Telefon raqamni formatlash: +998901234567 → +998 90 123 45 67
  String _formatPhone(String phone) {
    if (phone.length < 13) return phone;
    return '${phone.substring(0, 4)} ${phone.substring(4, 6)} ${phone.substring(6, 9)} ${phone.substring(9, 11)} ${phone.substring(11)}';
  }

  Widget _buildSubscriptionInfo(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withOpacity(0.04),
                const Color(0xFFFBBF24).withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👑 Obuna holati',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: state.isPremium
                          ? const Color(0xFF22C55E).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      state.isPremium ? 'Faol' : 'Faol emas',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: state.isPremium
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tarif',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    state.currentPlan?.label ?? 'Tanlanmagan',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tugash sanasi',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    state.currentSubscription != null
                        ? '${state.currentSubscription!.endDate.day.toString().padLeft(2, '0')}.${state.currentSubscription!.endDate.month.toString().padLeft(2, '0')}.${state.currentSubscription!.endDate.year}'
                        : '—',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
        fontFamily: 'Nunito',
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSwitch(bool value) {
    return Container(
      width: 42.w,
      height: 24.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: value ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            right: value ? 2.w : null,
            left: value ? null : 2.w,
            top: 2.h,
            child: Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowIcon() {
    return Text(
      '→',
      style: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutConfirmation(context),
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Chiqish 🚪',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }

  // ============= Dialoglar =============

  /// Profil tahrirlash dialog — ismni o'zgartirish
  void _showEditProfileDialog(BuildContext parentContext, String currentName) {
    final controller = TextEditingController(text: currentName);
    bool isSubmitted = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => BlocProvider.value(
        value: parentContext.read<AuthBloc>(),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (isSubmitted && state.status == AuthStatus.authenticated && state.errorMessage == null) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                  content: Text('Profil yangilandi ✅'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            } else if (isSubmitted && state.status == AuthStatus.error) {
              isSubmitted = false;
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Xatolik yuz berdi'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = isSubmitted && state.status == AuthStatus.loading;
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text(
                'Profilni tahrirlash',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  fontSize: 18.sp,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !isLoading,
                    style: TextStyle(
                      color: const Color(0xFF1A1A2E),
                      fontSize: 15.sp,
                      fontFamily: 'Nunito',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ism',
                      labelStyle: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 14.sp,
                      ),
                      hintText: 'Ismingizni kiriting',
                      hintStyle: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFF2D6A9F), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B7280)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Bekor qilish',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty && newName.length >= 2) {
                            isSubmitted = true;
                            context.read<AuthBloc>().add(UpdateProfileEvent(name: newName));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A9F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Saqlash',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// PIN o'zgartirish — premium bottom sheet
  void _showChangePinDialog(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _PinChangeSheet(phone: phone),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Chiqish',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            fontSize: 18.sp,
          ),
        ),
        content: const Text('Haqiqatan ham chiqishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Bekor qilish',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text(
              'Chiqish',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final Widget trailing;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsRow({
    required this.emoji,
    required this.bgColor,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PIN O'zgartirish — Premium Bottom Sheet (3 bosqichli)
// ============================================================

class _PinChangeSheet extends StatefulWidget {
  final String phone;

  const _PinChangeSheet({required this.phone});

  @override
  State<_PinChangeSheet> createState() => _PinChangeSheetState();
}

class _PinChangeSheetState extends State<_PinChangeSheet> {
  int _step = 0; // 0: joriy PIN, 1: yangi PIN, 2: tasdiqlash
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String _error = '';
  bool _isVerifying = false;

  static const int _pinLength = 4;
  static const _storage = FlutterSecureStorage();

  String get _activePin {
    switch (_step) {
      case 0:
        return _currentPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  /// Joriy PIN ni lokal tekshirish
  Future<void> _verifyCurrentPin() async {
    setState(() => _isVerifying = true);
    
    try {
      final savedHash = await _storage.read(key: 'pin_hash');
      final inputHash = base64Encode(utf8.encode('qadamcha_pin_$_currentPin'));
      
      if (savedHash != null && savedHash == inputHash) {
        // ✅ PIN to'g'ri — keyingi bosqichga
        if (mounted) {
          setState(() {
            _step = 1;
            _error = '';
            _isVerifying = false;
          });
        }
      } else {
        // ❌ PIN noto'g'ri
        if (mounted) {
          setState(() {
            _error = 'PIN kod noto\'g\'ri';
            _currentPin = '';
            _isVerifying = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Xatolik yuz berdi';
          _currentPin = '';
          _isVerifying = false;
        });
      }
    }
  }

  void _onDigit(String digit) {
    if (_activePin.length >= _pinLength || _isVerifying) return;
    setState(() {
      _error = '';
      switch (_step) {
        case 0:
          _currentPin += digit;
          if (_currentPin.length == _pinLength) {
            Future.delayed(const Duration(milliseconds: 200), _verifyCurrentPin);
          }
          break;
        case 1:
          _newPin += digit;
          if (_newPin.length == _pinLength) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _step = 2);
            });
          }
          break;
        case 2:
          _confirmPin += digit;
          if (_confirmPin.length == _pinLength) {
            Future.delayed(const Duration(milliseconds: 200), _submit);
          }
          break;
      }
    });
  }

  void _onBackspace() {
    if (_isVerifying) return;
    setState(() {
      _error = '';
      switch (_step) {
        case 0:
          if (_currentPin.isNotEmpty) {
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          }
          break;
        case 1:
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          } else {
            _step = 0;
          }
          break;
        case 2:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          } else {
            _step = 1;
          }
          break;
      }
    });
  }

  void _submit() {
    if (_newPin != _confirmPin) {
      setState(() {
        _error = 'PIN kodlar mos kelmadi';
        _confirmPin = '';
      });
      return;
    }
    
    // BLoC ga yuborish
    context.read<AuthBloc>().add(ChangePinEvent(
      currentPin: _currentPin,
      newPin: _newPin,
      phone: widget.phone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.authenticated ||
          curr.status == AuthStatus.error,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18.sp),
                  SizedBox(width: 8.w),
                  const Text(
                    'PIN kod muvaffaqiyatli o\'zgartirildi ✅',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _error = state.errorMessage ?? 'Xatolik yuz berdi';
            // Backend xatosi — birinchi bosqichga qaytarish
            _step = 0;
            _currentPin = '';
            _newPin = '';
            _confirmPin = '';
          });
        }
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              SizedBox(height: 20.h),

              // Title + Step indicator
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      _stepTitle,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _stepSubtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                        fontFamily: 'Nunito',
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Step indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final isActive = i <= _step;
                        final isCurrent = i == _step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: isCurrent ? 24.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF7C4DFF)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 28.h),

                    // PIN dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (i) {
                        final filled = i < _activePin.length;
                        final hasError = _error.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          width: 16.w,
                          height: 16.w,
                          decoration: BoxDecoration(
                            color: filled
                                ? (hasError
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF7C4DFF))
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasError
                                  ? const Color(0xFFEF4444)
                                  : filled
                                      ? const Color(0xFF7C4DFF)
                                      : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),

                    // Error text
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 18.h,
                      child: _error.isNotEmpty
                          ? Text(
                              _error,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Nunito',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Keypad
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: _buildKeypad(),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Joriy PIN kodni kiriting';
      case 1:
        return 'Yangi PIN yarating';
      case 2:
        return 'Tasdiqlang';
      default:
        return '';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0:
        return 'Xavfsizlik uchun hozirgi PIN kodingizni kiriting';
      case 1:
        return '4 xonali yangi PIN kodni o\'ylab toping';
      case 2:
        return 'Yangi PIN kodni qayta kiriting';
      default:
        return '';
    }
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'back']
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return SizedBox(width: 64.w, height: 52.h);
                }
                if (key == 'back') {
                  return _buildKeypadButton(
                    child: Icon(
                      Icons.backspace_outlined,
                      color: const Color(0xFF374151),
                      size: 22.sp,
                    ),
                    onTap: _onBackspace,
                  );
                }
                return _buildKeypadButton(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  onTap: () => _onDigit(key),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64.w,
        height: 52.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

