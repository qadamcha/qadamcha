import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';
import 'role_selection_page.dart';
import 'pin_reset_page.dart';

/// Login Page — parent_pin_page dizayniga mos
/// Oq fon, circle emoji icon, PinDots + PinKeypad
class LoginPage extends StatefulWidget {
  final String phone;

  const LoginPage({super.key, required this.phone});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _pin = '';
  String _error = '';
  bool _isLoading = false;
  String _deviceId = '';
  String _deviceName = '';
  String _deviceType = 'android';

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
      _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      _deviceType = 'android';
    } catch (_) {
      try {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown';
        _deviceName = iosInfo.name ?? iosInfo.model ?? 'iPhone';
        _deviceType = 'ios';
      } catch (_) {
        try {
          final windowsInfo = await deviceInfo.windowsInfo;
          _deviceId = windowsInfo.deviceId;
          _deviceName = windowsInfo.computerName;
          _deviceType = 'android'; // backend faqat android/ios qabul qiladi
        } catch (_) {
          _deviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
          _deviceName = 'Noma\'lum qurilma';
          _deviceType = 'android';
        }
      }
    }
  }

  void _onDigitEntered(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = '';
      });

      if (_pin.length == 4) {
        _login();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = '';
      });
    }
  }

  void _login() {
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(LoginEvent(
          phone: widget.phone,
          pin: _pin,
          deviceId: _deviceId,
          deviceName: _deviceName,
          deviceType: _deviceType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.authenticated ||
          curr.status == AuthStatus.error,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _isLoading = false;
            _error = state.errorMessage ?? 'PIN kod noto\'g\'ri';
            _pin = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textPrimary,
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Icon — parent_pin_page uslubida
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👋',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Greeting
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final name = state.user?.name ?? 'Foydalanuvchi';
                  return Text(
                    'Salom, $name!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              const Text(
                'PIN kodingizni kiriting',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),

              const SizedBox(height: 32),

              // PIN Dots — PinDots widgeti
              PinDots(
                currentLength: _pin.length,
                errorMessage: _error,
              ),

              const Spacer(flex: 2),

              // Forgot PIN
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PinResetPage()),
                  );
                },
                child: const Text(
                  'PIN kodni unutdingizmi?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Keypad — PinKeypad widgeti
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: PinKeypad(
                  onDigitEntered: _onDigitEntered,
                  onBackspace: _onBackspace,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
