import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';
import 'payment_success_page.dart';

/// Subscribe API orqali in-app karta to'lov sahifasi
/// WebView o'rniga karta formasi + SMS tasdiqlash
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

class _PaymentPageState extends State<PaymentPage> {
  final _cardNumberController = TextEditingController();
  final _expireController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _cardFocusNode = FocusNode();
  final _expireFocusNode = FocusNode();
  final _smsFocusNode = FocusNode();

  bool _showSmsInput = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expireController.dispose();
    _smsCodeController.dispose();
    _cardFocusNode.dispose();
    _expireFocusNode.dispose();
    _smsFocusNode.dispose();
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

  void _onSubmitCard() {
    if (!_isCardValid) return;
    context.read<SubscriptionBloc>().add(CreateCardTokenEvent(
      cardNumber: _rawCardNumber,
      expire: _rawExpire,
    ));
  }

  void _onSubmitSmsCode() {
    if (!_isSmsCodeValid) return;
    final token = context.read<SubscriptionBloc>().state.cardToken?.token;
    if (token == null) return;
    context.read<SubscriptionBloc>().add(VerifyCardEvent(
      token: token,
      code: _smsCodeController.text,
    ));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        switch (state.paymentStatus) {
          case PaymentStatus.cardTokenCreated:
            // Token yaratildi — SMS kod so'rash
            final token = state.cardToken?.token;
            if (token != null) {
              context.read<SubscriptionBloc>().add(
                GetVerifyCodeEvent(token: token),
              );
            }
            break;

          case PaymentStatus.verifyCodeSent:
            // SMS yuborildi — SMS input ko'rsatish
            setState(() => _showSmsInput = true);
            _smsFocusNode.requestFocus();
            break;

          case PaymentStatus.cardVerified:
            // Karta tasdiqlandi — to'lov qilish
            final token = state.cardToken?.token;
            if (token != null) {
              context.read<SubscriptionBloc>().add(PayWithTokenEvent(
                orderId: widget.orderId,
                token: token,
              ));
            }
            break;

          case PaymentStatus.success:
            // Muvaffaqiyat — ota-ona paneliga qaytish
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      'Obuna muvaffaqiyatli faollashtirildi!',
                      style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
            break;

          case PaymentStatus.failed:
            _showError(state.errorMessage ?? 'Xatolik yuz berdi');
            break;

          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                  builder: (context, state) {
                    if (_isProcessing(state.paymentStatus)) {
                      return _buildProcessingView(state.paymentStatus);
                    }
                    return _buildCardForm(state);
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

  bool _isProcessing(PaymentStatus status) {
    return status == PaymentStatus.creatingCardToken ||
           status == PaymentStatus.sendingVerifyCode ||
           status == PaymentStatus.verifyingCard ||
           status == PaymentStatus.paying;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          BackButtonBox(onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To\'lov',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _buildCardForm(SubscriptionState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Karta raqami
          const Text(
            'Karta raqami',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
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
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              fontFamily: 'Nunito',
            ),
            decoration: InputDecoration(
              hintText: '0000 0000 0000 0000',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('💳', style: TextStyle(fontSize: 20)),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _expireFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),

          // Amal qilish muddati
          const Text(
            'Amal qilish muddati',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
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
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                fontFamily: 'Nunito',
              ),
              decoration: InputDecoration(
                hintText: 'OO/YY',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // SMS kod input
          if (_showSmsInput) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📱', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SMS kod yuborildi: ${state.verifyCodeResult?.phone ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsCodeController,
                    focusNode: _smsFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '- - - - - -',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Submit tugmasi
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _getSubmitAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubmitEnabled()
                    ? AppColors.primary
                    : AppColors.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _getSubmitEnabled() ? 2 : 0,
              ),
              child: Text(
                _getSubmitText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Powered by Payme + Oferta + Xavfsizlik bayonoti
          // (Payme rasmiy protokoli talabi)
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Powered by Payme',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Karta ma\'lumotlari shifrlangan holda faqat\nPayme serverida saqlanadi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openPaymeOferta(),
                  child: Text(
                    'Payme ofertasi',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontFamily: 'Nunito',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getSubmitAction() {
    if (_showSmsInput) {
      return _isSmsCodeValid ? _onSubmitSmsCode : null;
    }
    return _isCardValid ? _onSubmitCard : null;
  }

  bool _getSubmitEnabled() {
    if (_showSmsInput) return _isSmsCodeValid;
    return _isCardValid;
  }

  String _getSubmitText() {
    if (_showSmsInput) return 'Tasdiqlash';
    return 'Davom etish';
  }

  Widget _buildProcessingView(PaymentStatus status) {
    String message;
    switch (status) {
      case PaymentStatus.creatingCardToken:
        message = 'Karta tekshirilmoqda...';
        break;
      case PaymentStatus.sendingVerifyCode:
        message = 'SMS kod yuborilmoqda...';
        break;
      case PaymentStatus.verifyingCard:
        message = 'Tasdiqlanmoqda...';
        break;
      case PaymentStatus.paying:
        message = 'To\'lov amalga oshirilmoqda...';
        break;
      default:
        message = 'Kutib turing...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Iltimos, kutib turing',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  /// Payme oferta sahifasini ochish (rasmiy protokol talabi)
  void _openPaymeOferta() {
    // Payme rasmiy oferta URL
    const ofertaUrl = 'https://cdn.payme.uz/terms/main.html';
    // URL ni brauzerda ochish
    // url_launcher paketi mavjud bo'lmasa, SnackBar ko'rsatamiz
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payme ofertasi: cdn.payme.uz/terms/main.html'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            'Payme xavfsiz to\'lov tizimi',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.success,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

// ============= Input Formatters =============

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
