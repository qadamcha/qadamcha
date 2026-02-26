import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/sms_auto_fill_service.dart';
import '../bloc/auth_bloc.dart';
import 'register_page.dart';
import 'login_page.dart';

/// OTP Page — Premium animated design
/// Gradient header, glassmorphism inputs, smooth animations
class OtpPage extends StatefulWidget {
  final String phone;

  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  // SMS Auto-fill
  late SmsAutoFillService _smsService;
  bool _autoFilled = false;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSmsAutoFill();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _initSmsAutoFill() {
    _smsService = SmsAutoFillService();
    _smsService.listenForSms(
      onCodeReceived: (code) {
        if (!mounted || _autoFilled) return;
        _autoFillOtp(code);
      },
    );
  }

  void _autoFillOtp(String code) {
    if (code.length != 6) return;
    setState(() {
      _autoFilled = true;
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = code[i];
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _verifyOtp();
    });
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _smsService.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _verifyOtp() {
    if (_otp.length == 6) {
      context.read<AuthBloc>().add(
            VerifyOtpEvent(phone: widget.phone, code: _otp),
          );
    }
  }

  void _resendOtp() {
    if (_canResend) {
      _autoFilled = false;
      _smsService.dispose();
      _initSmsAutoFill();
      context.read<AuthBloc>().add(SendOtpEvent(widget.phone));
      _startTimer();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    setState(() {});
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) {
      _verifyOtp();
    }
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Mask phone: +998901234567 -> +998 ** *** 45 67
  String get _maskedPhone {
    final p = widget.phone;
    if (p.length >= 13) {
      return '${p.substring(0, 4)} ** *** ${p.substring(9, 11)} ${p.substring(11)}';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        if (state.status == AuthStatus.otpVerified) {
          if (state.isNewUser) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterPage(phone: widget.phone),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginPage(phone: widget.phone),
              ),
            );
          }
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Kod noto'g'ri"),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          for (final controller in _controllers) {
            controller.clear();
          }
          _autoFilled = false;
          _focusNodes[0].requestFocus();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D6A9F),
                Color(0xFF1A4A73),
                Colors.white,
                Colors.white,
              ],
              stops: [0.0, 0.25, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),

                              // Shield icon with glow
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shield_outlined,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Title
                              const Text(
                                'Tasdiqlash kodi',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  letterSpacing: -0.5,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Phone number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _maskedPhone,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Nunito',
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'raqamiga yuborilgan kodni kiriting',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                  fontFamily: 'Nunito',
                                ),
                              ),

                              const SizedBox(height: 36),

                              // OTP Input Boxes — Premium design
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(6, (index) {
                                        final isFilled =
                                            _controllers[index].text.isNotEmpty;
                                        final isFocused =
                                            _focusNodes[index].hasFocus;
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 46,
                                          height: 56,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: isFilled
                                                ? AppColors.primary
                                                    .withOpacity(0.05)
                                                : isFocused
                                                    ? AppColors.primary
                                                        .withOpacity(0.03)
                                                    : const Color(0xFFF5F7FA),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isFilled
                                                  ? AppColors.primary
                                                  : isFocused
                                                      ? AppColors.primaryLight
                                                      : const Color(0xFFE2E8F0),
                                              width: isFilled || isFocused
                                                  ? 2
                                                  : 1.5,
                                            ),
                                            boxShadow: isFocused
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primary
                                                          .withOpacity(0.15),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: KeyboardListener(
                                            focusNode: FocusNode(),
                                            onKeyEvent: (event) =>
                                                _onKeyPress(index, event),
                                            child: TextField(
                                              controller: _controllers[index],
                                              focusNode: _focusNodes[index],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 1,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Nunito',
                                                color: isFilled
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                              decoration: const InputDecoration(
                                                counterText: '',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (value) =>
                                                  _onOtpDigitChanged(
                                                      index, value),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    const SizedBox(height: 24),

                                    // Timer / Resend
                                    _canResend
                                        ? GestureDetector(
                                            onTap: _resendOtp,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient:
                                                    AppColors.primaryGradient,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.refresh_rounded,
                                                      color: Colors.white,
                                                      size: 16),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Qayta yuborish',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      fontFamily: 'Nunito',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F4F8),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .timer_outlined,
                                                  size: 16,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Qayta yuborish $_formattedTime',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Nunito',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Submit button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isReady = _otp.length == 6 &&
                                      state.status != AuthStatus.loading;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: isReady ? _verifyOtp : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            const Color(0xFFE2E8F0),
                                        disabledForegroundColor:
                                            AppColors.textDisabled,
                                        elevation: isReady ? 4 : 0,
                                        shadowColor:
                                            AppColors.primary.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: state.status == AuthStatus.loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.verified_rounded,
                                                    size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Tasdiqlash',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Nunito',
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Security note
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ma\'lumotlaringiz shifrlangan va himoyalangan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary.withOpacity(0.6),
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
