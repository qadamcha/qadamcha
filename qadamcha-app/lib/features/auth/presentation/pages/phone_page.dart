import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/services/sms_auto_fill_service.dart';
import '../bloc/auth_bloc.dart';
import 'otp_page.dart';

/// Phone Page - matching full_architecture.html design
/// 📱 emoji header, +998 prefix, styled input
class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SmsAutoFillService? _smsService;

  String get _formattedPhone =>
      '+998${_phoneController.text.replaceAll(' ', '')}';

  @override
  void dispose() {
    _phoneController.dispose();
    _smsService?.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      // SMS listener'ni OLDIN boshlash (race condition oldini olish)
      _smsService = SmsAutoFillService();
      _smsService!.listenForSms(
        onCodeReceived: (code) {
          // OtpPage ga o'tgandan keyin callback ishlaydi
        },
      );

      context.read<AuthBloc>().add(SendOtpEvent(_formattedPhone));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Faqat aktiv sahifa bo'lgandagina ishlaydi
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        if (state.status == AuthStatus.otpSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpPage(
                phone: _formattedPhone,
                smsService: _smsService,
              ),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Xatolik yuz berdi'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Back button
                  BackButtonBox(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),
                  // Title with emoji
                  const Text(
                    '📱 Telefon raqamingiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SMS orqali tasdiqlash kodi yuboriladi',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Phone Input with blue border styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country Code
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '🇺🇿',
                                style: TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '+998',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.border,
                        ),
                        // Phone Number
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '90 123 45 67',
                              hintStyle: const TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 16,
                                fontFamily: 'Nunito',
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                              _PhoneNumberFormatter(),
                            ],
                            validator: (value) {
                              final digits =
                                  value?.replaceAll(' ', '') ?? '';
                              if (digits.length != 9) {
                                return "Telefon raqam 9 ta raqamdan iborat bo'lishi kerak";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sizga SMS orqali tasdiqlash kodi yuboriladi',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Submit Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return GradientButton(
                        onPressed: state.status == AuthStatus.loading
                            ? null
                            : _sendOtp,
                        isLoading: state.status == AuthStatus.loading,
                        text: 'Davom etish →',
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 4 || i == 6) && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
