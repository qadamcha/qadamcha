import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../bloc/auth_bloc.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'phone_page.dart';

/// Login Page - matching full_architecture.html design  
/// Avatar with gradient, personal greeting, dot indicators, custom keypad
class LoginPage extends StatefulWidget {
  final String phone;

  const LoginPage({super.key, required this.phone});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _pin = '';
  final int _pinLength = 4;
  String _deviceId = '';
  String? _userName;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
    // TODO: Get user name from state/storage
    _userName = null; // Will be fetched from bloc
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } catch (_) {
      try {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } catch (_) {
        try {
          final windowsInfo = await deviceInfo.windowsInfo;
          _deviceId = windowsInfo.deviceId;
        } catch (_) {
          _deviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
        }
      }
    }
  }

  void _onKeyPressed(String key) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += key;
      });
      if (_pin.length == _pinLength) {
        _login();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _login() {
    context.read<AuthBloc>().add(LoginEvent(
          phone: widget.phone,
          pin: _pin,
          deviceId: _deviceId,
        ));
  }

  void _forgotPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _ResetPinFlowPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "PIN kod noto'g'ri"),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _pin = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Avatar with gradient
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('👋', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 18),
                // Greeting
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final name = state.user?.name ?? _userName ?? 'Foydalanuvchi';
                    return Text(
                      'Salom, $name!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'PIN kodingizni kiriting',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 36),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? AppColors.primary : AppColors.border,
                          width: 2.5,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Forgot PIN link
                GestureDetector(
                  onTap: _forgotPin,
                  child: Text(
                    'PIN kodni unutdingizmi?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                const Spacer(),
                // Keypad
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state.status == AuthStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return CustomKeypad(
                      onKeyPressed: _onKeyPressed,
                      onBackspace: _onBackspace,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN Reset Flow - multi-step page for resetting PIN
class _ResetPinFlowPage extends StatefulWidget {
  const _ResetPinFlowPage();

  @override
  State<_ResetPinFlowPage> createState() => _ResetPinFlowPageState();
}

class _ResetPinFlowPageState extends State<_ResetPinFlowPage> {
  final _phoneController = TextEditingController(text: '+998');
  String _otp = '';
  String _newPin = '';
  int _step = 0; // 0: Phone, 1: OTP, 2: New PIN

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneController.text.length >= 13) {
      context.read<AuthBloc>().add(SendOtpEvent(_phoneController.text));
    }
  }

  void _verifyOtp() {
    if (_otp.length == 6) {
      context.read<AuthBloc>().add(VerifyOtpEvent(
            phone: _phoneController.text,
            code: _otp,
          ));
    }
  }

  void _resetPin() {
    if (_newPin.length == 4) {
      context.read<AuthBloc>().add(ResetPinEvent(
            phone: _phoneController.text,
            newPin: _newPin,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.otpSent && _step == 0) {
          setState(() => _step = 1);
        } else if (state.status == AuthStatus.otpVerified && _step == 1) {
          setState(() => _step = 2);
        } else if (state.status == AuthStatus.pinReset) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN kod muvaffaqiyatli yangilandi!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(phone: _phoneController.text),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Xatolik yuz berdi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (_step > 0) {
                        setState(() {
                          _step--;
                          if (_step == 0) _otp = '';
                          if (_step == 1) _newPin = '';
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _step == 2
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _step == 0 ? '🔓' : (_step == 1 ? '✉️' : '🔑'),
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                Text(
                  _step == 0
                      ? 'PIN tiklash'
                      : (_step == 1 ? 'Kodni tasdiqlang' : 'Yangi PIN yarating'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _step == 0
                      ? 'Telefon raqamingizni kiriting'
                      : (_step == 1
                          ? '${_phoneController.text} ga kod yuborildi'
                          : 'Xavfsiz 4 raqamli PIN tanlang'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 28),
                // Content based on step
                if (_step == 0) ...[
                  // Phone input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                    decoration: InputDecoration(
                      hintText: '+998 90 123 45 67',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Continue button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: state.status == AuthStatus.loading
                            ? null
                            : _sendOtp,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: state.status == AuthStatus.loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Davom etish →',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else if (_step == 1) ...[
                  // OTP input dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _otp.length;
                      return Container(
                        width: 46,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isFilled
                              ? AppColors.primary.withOpacity(0.06)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFilled
                                ? AppColors.primary
                                : AppColors.border,
                            width: isFilled ? 2.5 : 2,
                          ),
                        ),
                        child: Center(
                          child: isFilled
                              ? Text(
                                  _otp[index],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Nunito',
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Keypad for OTP
                  CustomKeypad(
                    onKeyPressed: (key) {
                      if (_otp.length < 6) {
                        setState(() => _otp += key);
                        if (_otp.length == 6) _verifyOtp();
                      }
                    },
                    onBackspace: () {
                      if (_otp.isNotEmpty) {
                        setState(
                            () => _otp = _otp.substring(0, _otp.length - 1));
                      }
                    },
                  ),
                ] else ...[
                  // New PIN input dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _newPin.length;
                      return Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isFilled ? AppColors.success : Colors.transparent,
                          border: Border.all(
                            color: isFilled
                                ? AppColors.success
                                : AppColors.border,
                            width: 2.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Keypad for new PIN
                  CustomKeypad(
                    onKeyPressed: (key) {
                      if (_newPin.length < 4) {
                        setState(() => _newPin += key);
                        if (_newPin.length == 4) _resetPin();
                      }
                    },
                    onBackspace: () {
                      if (_newPin.isNotEmpty) {
                        setState(() =>
                            _newPin = _newPin.substring(0, _newPin.length - 1));
                      }
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
