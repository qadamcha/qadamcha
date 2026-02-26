import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';
import 'payment_success_page.dart';

/// Premium To'lov Sahifasi — Payme Subscribe API
/// 3D karta preview, step indicator, smart karta aniqlash
class PaymentPage extends StatefulWidget {
  final SubscriptionPlan plan;
  final String orderId;

  const PaymentPage({
    super.key,
    required this.plan,
    required this.orderId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  final _cardNumberController = TextEditingController();
  final _expireController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _cardFocusNode = FocusNode();
  final _expireFocusNode = FocusNode();
  final _smsFocusNode = FocusNode();

  // Step tracking: 0=Card, 1=SMS, 2=Processing
  int _currentStep = 0;

  // SMS resend countdown
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  // Code expiry countdown (60s)
  Timer? _codeExpiryTimer;
  int _codeExpirySeconds = 0;
  bool _isCodeExpired = false;

  // Block timer (5 min)
  Timer? _blockTimer;
  int _blockSeconds = 0;
  bool _isBlocked = false;

  // Verify attempts
  int _attemptsLeft = 3;

  // Animations
  late AnimationController _cardAnimController;
  late Animation<double> _cardTiltAnimation;
  late AnimationController _stepAnimController;
  late Animation<double> _stepFadeAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardTiltAnimation = Tween<double>(begin: 0, end: 0.03).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeInOut),
    );

    _stepAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _stepFadeAnimation = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );

    // Auto-focus card field
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expireController.dispose();
    _smsCodeController.dispose();
    _cardFocusNode.dispose();
    _expireFocusNode.dispose();
    _smsFocusNode.dispose();
    _countdownTimer?.cancel();
    _codeExpiryTimer?.cancel();
    _blockTimer?.cancel();
    _cardAnimController.dispose();
    _stepAnimController.dispose();
    super.dispose();
  }

  String get _rawCardNumber =>
      _cardNumberController.text.replaceAll(' ', '');

  String get _rawExpire =>
      _expireController.text.replaceAll('/', '');

  bool get _isCardValid =>
      _rawCardNumber.length == 16 && _rawExpire.length == 4;

  bool get _isSmsCodeValid =>
      _smsCodeController.text.length == 6;

  /// Karta turini aniqlash (BIN prefiks bo'yicha)
  _CardType get _detectedCardType {
    final num = _rawCardNumber;
    if (num.startsWith('8600')) return _CardType.uzcard;
    if (num.startsWith('9860')) return _CardType.humo;
    if (num.startsWith('4')) return _CardType.visa;
    if (num.startsWith('5')) return _CardType.mastercard;
    return _CardType.unknown;
  }

  void _startCountdown(int seconds) {
    _countdownSeconds = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _startCodeExpiryTimer() {
    _codeExpirySeconds = 60;
    _isCodeExpired = false;
    _codeExpiryTimer?.cancel();
    _codeExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _codeExpirySeconds--;
        if (_codeExpirySeconds <= 0) {
          timer.cancel();
          _isCodeExpired = true;
        }
      });
    });
  }

  void _startBlockTimer(int seconds) {
    _blockSeconds = seconds;
    _isBlocked = true;
    _blockTimer?.cancel();
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _blockSeconds--;
        if (_blockSeconds <= 0) {
          timer.cancel();
          _isBlocked = false;
          _attemptsLeft = 3;
        }
      });
    });
  }

  /// Error message'dan block/expired/attempts holatini aniqlash
  void _parseErrorForRateLimit(String message) {
    // "X soniya kutib turing" — bloklangan
    final blockMatch = RegExp(r'(\d+) soniya kutib turing').firstMatch(message);
    if (blockMatch != null && (message.contains('noto\'g\'ri kod') || message.contains('noto\'g\'ri'))) {
      final seconds = int.tryParse(blockMatch.group(1)!) ?? 300;
      _startBlockTimer(seconds);
      _attemptsLeft = 0;
      return;
    }
    // "muddati tugagan" — kod eskirgan
    if (message.contains('muddati tugagan') || message.contains('qayta yuborish')) {
      setState(() => _isCodeExpired = true);
      return;
    }
  }

  void _onSubmitCard() {
    if (!_isCardValid) return;
    // Animate card
    _cardAnimController.forward().then((_) {
      if (mounted) _cardAnimController.reverse();
    });
    context.read<SubscriptionBloc>().add(CreateCardTokenEvent(
      cardNumber: _rawCardNumber,
      expire: _rawExpire,
    ));
  }

  void _onSubmitSmsCode() {
    if (!_isSmsCodeValid || _isCodeExpired || _isBlocked) return;
    final token = context.read<SubscriptionBloc>().state.cardToken?.token;
    if (token == null) return;
    context.read<SubscriptionBloc>().add(VerifyCardEvent(
      token: token,
      code: _smsCodeController.text,
    ));
  }

  void _resendSmsCode() {
    if (_countdownSeconds > 0 || _isBlocked) return;
    _smsCodeController.clear();
    setState(() => _isCodeExpired = false);
    final token = context.read<SubscriptionBloc>().state.cardToken?.token;
    if (token == null) return;
    context.read<SubscriptionBloc>().add(GetVerifyCodeEvent(token: token));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _animateToStep(int step) {
    _stepAnimController.reset();
    setState(() => _currentStep = step);
    _stepAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        switch (state.paymentStatus) {
          case PaymentStatus.cardTokenCreated:
            final token = state.cardToken?.token;
            if (token != null) {
              context.read<SubscriptionBloc>().add(
                GetVerifyCodeEvent(token: token),
              );
            }
            break;

          case PaymentStatus.verifyCodeSent:
            _animateToStep(1);
            // Payme wait qiymatini millisekunddan sekundga aylantirish
            final waitMs = state.verifyCodeResult?.wait ?? 60;
            final waitSeconds = waitMs > 1000 ? (waitMs / 1000).round() : waitMs;
            _startCountdown(waitSeconds);
            _startCodeExpiryTimer();
            _attemptsLeft = 3;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _smsFocusNode.requestFocus();
            });
            break;

          case PaymentStatus.cardVerified:
            _animateToStep(2);
            final token = state.cardToken?.token;
            if (token != null) {
              context.read<SubscriptionBloc>().add(PayWithTokenEvent(
                orderId: widget.orderId,
                token: token,
              ));
            }
            break;

          case PaymentStatus.success:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentSuccessPage(plan: widget.plan),
              ),
            );
            break;

          case PaymentStatus.failed:
            // Reset to appropriate step
            if (_currentStep == 2) {
              _animateToStep(_currentStep > 0 ? 1 : 0);
            }
            final errorMsg = state.errorMessage ?? 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
            _parseErrorForRateLimit(errorMsg);
            _showError(errorMsg);
            break;

          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepIndicator(),
              Expanded(
                child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                  builder: (context, state) {
                    return FadeTransition(
                      opacity: _stepFadeAnimation,
                      child: _buildCurrentStep(state),
                    );
                  },
                ),
              ),
              _buildSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(SubscriptionState state) {
    if (_isProcessing(state.paymentStatus)) {
      return _buildProcessingView(state.paymentStatus);
    }
    if (_currentStep == 1) {
      return _buildSmsStep(state);
    }
    return _buildCardStep(state);
  }

  bool _isProcessing(PaymentStatus status) {
    return status == PaymentStatus.creatingCardToken ||
        status == PaymentStatus.sendingVerifyCode ||
        status == PaymentStatus.verifyingCard ||
        status == PaymentStatus.paying;
  }

  // ============= HEADER =============

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          BackButtonBox(onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xavfsiz to\'lov',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.plan.label} — ${widget.plan.formattedPrice}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          // Security badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 13, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'SSL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
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

  // ============= STEP INDICATOR =============

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(0, 'Karta', Icons.credit_card),
          _buildStepLine(0),
          _buildStepDot(1, 'SMS', Icons.sms_outlined),
          _buildStepLine(1),
          _buildStepDot(2, 'To\'lov', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                    )
                  : null,
              color: isActive ? null : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D6A9F).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF2D6A9F) : AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2D6A9F) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ============= CARD STEP =============

  Widget _buildCardStep(SubscriptionState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 3D Card Preview
          _build3DCardPreview(),

          const SizedBox(height: 24),

          // Card number field
          _buildInputLabel('Karta raqami', Icons.credit_card),
          const SizedBox(height: 8),
          _buildCardNumberField(),

          const SizedBox(height: 18),

          // Expire + Card type row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Amal muddati', Icons.calendar_today),
                    const SizedBox(height: 8),
                    _buildExpireField(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Karta turi', Icons.style),
                    const SizedBox(height: 8),
                    _buildCardTypeIndicator(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Submit button
          _buildGradientButton(
            text: 'Davom etish',
            onPressed: _isCardValid ? _onSubmitCard : null,
            icon: Icons.arrow_forward_rounded,
          ),

          const SizedBox(height: 20),

          // Payme branding + Oferta
          _buildPaymeBranding(),
        ],
      ),
    );
  }

  // ============= 3D CARD PREVIEW =============

  Widget _build3DCardPreview() {
    final cardNum = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final expire = _expireController.text.isEmpty
        ? '••/••'
        : _expireController.text;
    final cardType = _detectedCardType;

    return AnimatedBuilder(
      animation: _cardTiltAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_cardTiltAnimation.value),
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardType.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cardType.gradientColors.first.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: cardType.gradientColors.last.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: chip + card type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Chip
                          Container(
                            width: 42,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDAA520), Color(0xFFFAD461)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.memory,
                                size: 16,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                          ),
                          // Card type logo/text
                          Text(
                            cardType.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Card number
                      Text(
                        cardNum,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Bottom row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AMAL MUDDATI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontFamily: 'Nunito',
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                expire,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          // Contactless icon
                          Transform.rotate(
                            angle: math.pi / 2,
                            child: Icon(
                              Icons.wifi,
                              size: 28,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============= INPUT FIELDS =============

  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildCardNumberField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _cardNumberController,
        focusNode: _cardFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          _CardNumberFormatter(),
        ],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
          fontFamily: 'Nunito',
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '0000 0000 0000 0000',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2D6A9F), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A9F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.credit_card,
              size: 18,
              color: Color(0xFF2D6A9F),
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _expireFocusNode.requestFocus(),
      ),
    );
  }

  Widget _buildExpireField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _expireController,
        focusNode: _expireFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
          _ExpireDateFormatter(),
        ],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          fontFamily: 'Nunito',
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'OO/YY',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2D6A9F), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_isCardValid) _onSubmitCard();
        },
      ),
    );
  }

  Widget _buildCardTypeIndicator() {
    final type = _detectedCardType;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      decoration: BoxDecoration(
        color: type == _CardType.unknown
            ? Colors.white
            : type.gradientColors.first.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: type == _CardType.unknown
              ? AppColors.border.withValues(alpha: 0.5)
              : type.gradientColors.first.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            type == _CardType.unknown ? '—' : type.displayName,
            key: ValueKey(type),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: type == _CardType.unknown
                  ? AppColors.textSecondary
                  : type.gradientColors.first,
              fontFamily: 'Nunito',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============= SMS STEP =============

  Widget _buildSmsStep(SubscriptionState state) {
    final phone = state.verifyCodeResult?.phone ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Phone illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D6A9F).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.sms_outlined, size: 36, color: Colors.white),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'SMS kodni kiriting',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tasdiqlash kodi $phone raqamiga yuborildi',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              height: 1.4,
            ),
          ),

          const SizedBox(height: 28),

          // Code expiry indicator
          if (!_isBlocked) _buildCodeExpiryBar(),

          const SizedBox(height: 12),

          // Block overlay OR normal flow
          if (_isBlocked) _buildBlockedOverlay(),

          if (!_isBlocked) ...[          
            // SMS code field (premium)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_isCodeExpired
                        ? Colors.amber
                        : const Color(0xFF2D6A9F)).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _smsCodeController,
                focusNode: _smsFocusNode,
                keyboardType: TextInputType.number,
                enabled: !_isCodeExpired,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                  fontFamily: 'Nunito',
                  color: _isCodeExpired
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    letterSpacing: 12,
                    fontSize: 28,
                  ),
                  filled: true,
                  fillColor: _isCodeExpired
                      ? Colors.grey.shade50
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _isCodeExpired
                          ? Colors.amber.withValues(alpha: 0.5)
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D6A9F),
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Attempts left indicator
            if (_attemptsLeft < 3 && _attemptsLeft > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 14,
                        color: _attemptsLeft == 1 ? Colors.red : Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '$_attemptsLeft ta urinish qoldi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                        color: _attemptsLeft == 1 ? Colors.red : Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Countdown / Resend
            _buildResendButton(),

            const SizedBox(height: 28),

            // Confirm button
            _buildGradientButton(
              text: _isCodeExpired ? 'Kod muddati tugadi' : 'Tasdiqlash',
              onPressed: (_isSmsCodeValid && !_isCodeExpired) ? _onSubmitSmsCode : null,
              icon: _isCodeExpired ? Icons.timer_off_outlined : Icons.verified_outlined,
            ),
          ],

          const SizedBox(height: 16),

          // Back to card step
          TextButton.icon(
            onPressed: () {
              _animateToStep(0);
              _smsCodeController.clear();
              _countdownTimer?.cancel();
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              'Kartani qayta kiritish',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    // Blocked state
    if (_isBlocked) {
      return const SizedBox.shrink(); // Block overlay already shown
    }

    // Code expired — show resend prompt
    if (_isCodeExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_outlined, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            const Text(
              'Kod muddati tugadi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _resendSmsCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A9F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Qayta yuborish',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Countdown active
    if (_countdownSeconds > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A9F).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF2D6A9F)),
            const SizedBox(width: 6),
            Text(
              'Qayta yuborish: ${_countdownSeconds}s',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D6A9F),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      );
    }

    // Ready to resend
    return TextButton.icon(
      onPressed: _resendSmsCode,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text(
        'SMS kodni qayta yuborish',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A9F),
      ),
    );
  }

  // Code expiry progress bar
  Widget _buildCodeExpiryBar() {
    if (_codeExpirySeconds <= 0 && _isCodeExpired) {
      return const SizedBox.shrink();
    }
    if (_codeExpirySeconds <= 0) return const SizedBox.shrink();
    
    final progress = _codeExpirySeconds / 60.0;
    final isLow = _codeExpirySeconds <= 15;
    final color = isLow ? Colors.red : const Color(0xFF2D6A9F);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLow ? Icons.warning_amber_rounded : Icons.schedule,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              'Kod muddati: ${_codeExpirySeconds}s',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey.shade200,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Blocked overlay
  Widget _buildBlockedOverlay() {
    final minutes = _blockSeconds ~/ 60;
    final seconds = _blockSeconds % 60;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, size: 28, color: Colors.red),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vaqtincha bloklangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.red,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ko\'p marta noto\'g\'ri kod kiritdingiz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 16),
          // Big countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.red,
                fontFamily: 'Nunito',
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Qayta urinish uchun kutib turing',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  // ============= PROCESSING VIEW =============

  Widget _buildProcessingView(PaymentStatus status) {
    String message;
    String subMessage;
    IconData icon;
    switch (status) {
      case PaymentStatus.creatingCardToken:
        message = 'Karta tekshirilmoqda...';
        subMessage = 'Karta ma\'lumotlari xavfsiz uzatilmoqda';
        icon = Icons.credit_card;
        break;
      case PaymentStatus.sendingVerifyCode:
        message = 'SMS yuborilmoqda...';
        subMessage = 'Tasdiqlash kodi telefoningizga yuboriladi';
        icon = Icons.sms_outlined;
        break;
      case PaymentStatus.verifyingCard:
        message = 'Tasdiqlanmoqda...';
        subMessage = 'Karta ma\'lumotlari tekshirilmoqda';
        icon = Icons.verified_user_outlined;
        break;
      case PaymentStatus.paying:
        message = 'To\'lov amalga oshirilmoqda...';
        subMessage = '256-bit shifrlangan aloqa';
        icon = Icons.payments_outlined;
        break;
      default:
        message = 'Kutib turing...';
        subMessage = '';
        icon = Icons.hourglass_empty;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated processing icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A9F), Color(0xFF1A4A73)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D6A9F).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          // Spinner
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D6A9F)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                subMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= SHARED WIDGETS =============

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF2D6A9F), Color(0xFF1A4A73)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D6A9F).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: enabled ? Colors.white : AppColors.textSecondary,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymeBranding() {
    return Center(
      child: Column(
        children: [
          // Payme logo row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Powered by',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/icons/payme_logo.png',
                height: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                'Karta ma\'lumotlari Payme serverida xavfsiz saqlanadi',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Oferta link
          GestureDetector(
            onTap: _openPaymeOferta,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF2D6A9F).withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Payme ofertasi shartlari →',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2D6A9F),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Payme oferta — brauzerda ochish
  Future<void> _openPaymeOferta() async {
    final uri = Uri.parse('https://cdn.payme.uz/terms/main.html');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback: platformDefault mode bilan urinish
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) {
          _showError('Brauzer ochilmadi. Iltimos, qo\'lda oching: cdn.payme.uz/terms/main.html');
        }
      }
    }
  }

  // ============= SECURITY FOOTER =============

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: AppColors.success.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(
            '256-bit SSL shifrlangan',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 12,
            color: AppColors.border,
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/icons/payme_logo.png',
            height: 16,
          ),
        ],
      ),
    );
  }
}

// ============= CARD TYPE ENUM =============

enum _CardType {
  uzcard,
  humo,
  visa,
  mastercard,
  unknown;

  String get displayName {
    switch (this) {
      case _CardType.uzcard:
        return 'UzCard';
      case _CardType.humo:
        return 'HUMO';
      case _CardType.visa:
        return 'VISA';
      case _CardType.mastercard:
        return 'MasterCard';
      case _CardType.unknown:
        return '';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case _CardType.uzcard:
        return [const Color(0xFF00599D), const Color(0xFF0088DD)];
      case _CardType.humo:
        return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      case _CardType.visa:
        return [const Color(0xFF1A1F71), const Color(0xFF3A4DB7)];
      case _CardType.mastercard:
        return [const Color(0xFFEB001B), const Color(0xFFF79E1B)];
      case _CardType.unknown:
        return [const Color(0xFF1A2A44), const Color(0xFF2D4A6E)];
    }
  }
}

// ============= INPUT FORMATTERS =============

/// Karta raqamini 4-4-4-4 formatda ko'rsatish
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Amal qilish muddatini MM/YY formatda ko'rsatish
class _ExpireDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
