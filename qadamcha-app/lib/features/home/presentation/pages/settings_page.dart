import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../device/presentation/bloc/device_bloc.dart';
import '../../../device/presentation/pages/device_linking_page.dart';

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
              child: SingleChildScrollView(
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
                        onTap: () {},
                      ),
                      _SettingsRow(
                        emoji: '❓',
                        bgColor: const Color(0xFF6B7280).withOpacity(0.08),
                        title: 'Yordam markazi',
                        trailing: _arrowIcon(),
                        onTap: () {},
                      ),
                      _SettingsRow(
                        emoji: 'ℹ️',
                        bgColor: const Color(0xFF6B7280).withOpacity(0.08),
                        title: 'Ilova haqida',
                        trailing: Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF9CA3AF),
                            fontFamily: 'Nunito',
                          ),
                        ),
                        onTap: () {},
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
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
              decoration: InputDecoration(
                labelText: 'Ism',
                hintText: 'Ismingizni kiriting',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName.length >= 2) {
                context.read<AuthBloc>().add(UpdateProfileEvent(name: newName));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil yangilandi ✅'),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A9F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text(
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
      ),
    );
  }

  /// PIN o'zgartirish dialog
  void _showChangePinDialog(BuildContext context, String phone) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'PIN kodni o\'zgartirish',
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
                controller: currentPinController,
                decoration: InputDecoration(
                  labelText: 'Joriy PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: newPinController,
                decoration: InputDecoration(
                  labelText: 'Yangi PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.lock_open),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: confirmPinController,
                decoration: InputDecoration(
                  labelText: 'Yangi PIN (tasdiqlash)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: errorText,
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                final currentPin = currentPinController.text.trim();
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                if (currentPin.length < 4) {
                  setDialogState(() => errorText = 'Joriy PIN noto\'g\'ri');
                  return;
                }
                if (newPin.length < 4) {
                  setDialogState(() => errorText = 'Yangi PIN kamida 4 raqam');
                  return;
                }
                if (newPin != confirmPin) {
                  setDialogState(() => errorText = 'PIN kodlar mos kelmadi');
                  return;
                }

                // Avval joriy PIN tekshirish, keyin yangilash
                context.read<AuthBloc>().add(ChangePinEvent(
                  currentPin: currentPin,
                  newPin: newPin,
                  phone: phone,
                ));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN kod yangilanmoqda...'),
                    backgroundColor: Color(0xFF2D6A9F),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
              child: Text(
                'O\'zgartirish',
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
