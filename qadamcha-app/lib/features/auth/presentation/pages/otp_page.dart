import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/services/sms_auto_fill_service.dart';
import '../bloc/auth_bloc.dart';
import 'register_page.dart';
import 'login_page.dart';

/// OTP Page - matching full_architecture.html design
/// ✉️ icon, 6-digit input boxes, countdown timer
/// SMS Auto-fill orqali avtomatik to'ldiriladi (Android)
class OtpPage extends StatefulWidget {
  final String phone;

  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  // SMS Auto-fill service
  late SmsAutoFillService _smsService;
  bool _autoFilled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSmsAutoFill();
  }

  /// SMS Auto-fill ni boshlash
  void _initSmsAutoFill() {
    _smsService = SmsAutoFillService();
    _smsService.listenForSms(
      onCodeReceived: (code) {
        if (!mounted || _autoFilled) return;
        _autoFillOtp(code);
      },
    );
  }

  /// Kelgan kodni 6 ta inputga tarqatish va avtomatik verify
  void _autoFillOtp(String code) {
    if (code.length != 6) return;

    setState(() {
      _autoFilled = true;
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = code[i];
      }
    });

    // Smooth UX: biroz kutib keyin verify
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
    _smsService.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
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
      // Reset auto-fill flag va qayta tinglash
      _autoFilled = false;
      _smsService.dispose();
      _initSmsAutoFill();

      context.read<AuthBloc>().add(SendOtpEvent(widget.phone));
      _startTimer();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Faqat aktiv sahifa bo'lgandagina ishlaydi
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
            ),
          );
          // Clear all fields
          for (final controller in _controllers) {
            controller.clear();
          }
          _autoFilled = false;
          _focusNodes[0].requestFocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Back button
                            BackButtonBox(
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 24),
                            // Icon and title
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text('✉️', style: TextStyle(fontSize: 36)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'Tasdiqlash kodi',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.phone} raqamiga\nyuborilgan kodni kiriting',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // OTP Input boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: 40, // Reduced from 48
                                  height: 50, // Reduced from 56
                                  margin: const EdgeInsets.symmetric(horizontal: 3), // Reduced from 5
                                  child: KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (event) => _onKeyPress(index, event),
                                    child: TextField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: const TextStyle(
                                        fontSize: 20, // Reduced from 22
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Nunito',
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        contentPadding: EdgeInsets.zero,
                                        fillColor: _controllers[index].text.isNotEmpty
                                            ? AppColors.primary.withOpacity(0.06)
                                            : AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Reduced radius
                                          borderSide: BorderSide(
                                            color: AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: _controllers[index].text.isNotEmpty
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) =>
                                          _onOtpDigitChanged(index, value),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                            // Resend Timer
                            Center(
                              child: _canResend
                                  ? GestureDetector(
                                      onTap: _resendOtp,
                                      child: Text(
                                        '🔄 Kodni qayta yuborish',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '⏱️ Qayta yuborish $_formattedTime',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        // Submit Button Section
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return GradientButton(
                                  onPressed: _otp.length == 6 &&
                                          state.status != AuthStatus.loading
                                      ? _verifyOtp
                                      : null,
                                  isLoading: state.status == AuthStatus.loading,
                                  text: 'Tasdiqlash ✓',
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
