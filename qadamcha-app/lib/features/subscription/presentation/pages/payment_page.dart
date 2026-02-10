import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/subscription_entity.dart';
import 'payment_success_page.dart';

/// Payment Page - Card details entry
/// Matching full_architecture.html design with card preview
class PaymentPage extends StatefulWidget {
  final SubscriptionPlan plan;
  final String paymentMethod;

  const PaymentPage({
    super.key,
    required this.plan,
    required this.paymentMethod,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _saveCard = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _paymentMethodIcon {
    switch (widget.paymentMethod) {
      case 'payme':
        return '💳';
      case 'click':
        return '📱';
      case 'uzum':
        return '🏪';
      default:
        return '💳';
    }
  }

  String get _paymentMethodName {
    switch (widget.paymentMethod) {
      case 'payme':
        return 'Payme';
      case 'click':
        return 'Click';
      case 'uzum':
        return 'Uzum Bank';
      default:
        return 'Karta';
    }
  }

  void _processPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(plan: widget.plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  BackButtonBox(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  Text(
                    '$_paymentMethodIcon $_paymentMethodName orqali to\'lov',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.sunsetGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              widget.plan.emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.plan.label,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                  Text(
                                    widget.plan.formattedPrice,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card preview
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '💳',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                  Text(
                                    _paymentMethodName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontFamily: 'Nunito',
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                _cardNumberController.text.isEmpty
                                    ? '•••• •••• •••• ••••'
                                    : _formatDisplayCardNumber(_cardNumberController.text),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _nameController.text.isEmpty
                                        ? 'CARDHOLDER NAME'
                                        : _nameController.text.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontFamily: 'Nunito',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    _expiryController.text.isEmpty
                                        ? 'MM/YY'
                                        : _expiryController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card Number
                      _buildLabel('Karta raqami'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          _CardNumberFormatter(),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration('8600 •••• •••• ••••'),
                        validator: (v) => (v?.replaceAll(' ', '').length ?? 0) < 16
                            ? 'Karta raqamini to\'liq kiriting'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Expiry and CVV
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Amal qilish'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryFormatter(),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  decoration: _inputDecoration('MM/YY'),
                                  validator: (v) => (v?.length ?? 0) < 5
                                      ? 'MM/YY formatda kiriting'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('CVV'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: _inputDecoration('•••'),
                                  validator: (v) => (v?.length ?? 0) < 3
                                      ? '3 ta raqam kiriting'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Cardholder Name
                      _buildLabel('Karta egasi'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration('ALISHER KARIMOV'),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Ismingizni kiriting'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Save card checkbox
                      GestureDetector(
                        onTap: () => setState(() => _saveCard = !_saveCard),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _saveCard
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _saveCard
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: _saveCard
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kartani keyingi to\'lovlar uchun saqlash',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Pay Button
                      GradientButton(
                        onPressed: _isLoading ? null : _processPayment,
                        isLoading: _isLoading,
                        text: 'To\'lash ${widget.plan.formattedPrice}',
                        variant: GradientButtonVariant.gold,
                      ),
                      const SizedBox(height: 16),

                      // Security note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('🔒', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'To\'lovlaringiz SSL shifrlash bilan himoyalangan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: 'Nunito',
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textDisabled,
        fontSize: 15,
        fontFamily: 'Nunito',
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatDisplayCardNumber(String input) {
    final cleaned = input.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      buffer.write(cleaned[i]);
      if ((i + 1) % 4 == 0 && i != cleaned.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
