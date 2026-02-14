import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';

/// Device QR Code Page - Shows QR code for child device to scan
/// Uses real QR code generation with qr_flutter package
class DeviceQrCodePage extends StatefulWidget {
  final String? familyCode;

  const DeviceQrCodePage({super.key, this.familyCode});

  @override
  State<DeviceQrCodePage> createState() => _DeviceQrCodePageState();
}

class _DeviceQrCodePageState extends State<DeviceQrCodePage> {
  late String _familyCode;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _familyCode = widget.familyCode ?? _generateFamilyCode();
  }

  String _generateFamilyCode() {
    // Generate a 6-character alphanumeric code
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(now + i * 17) % chars.length]).join();
  }

  /// QR code data format: qadamcha://link?code=XXXXXX&type=family
  String get _qrData => 'qadamcha://link?code=$_familyCode&type=family';

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _familyCode));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _shareCode() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Oila kodi: $_familyCode'),
        backgroundColor: AppColors.primary,
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
                  const Text(
                    '📲 Qurilma ulash',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🔗', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Farzandingiz telefonini ulang',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR kodni skanerlang yoki oila kodini kiriting',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Real QR Code
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textPrimary,
                        ),
                        embeddedImage: null, // Can add logo here
                        embeddedImageStyle: null,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'yoki',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Family code box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.05),
                            AppColors.purple.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Oila kodi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _familyCode.split('').map((char) {
                              return Container(
                                width: 44,
                                height: 54,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    char,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _copyCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _copied
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _copied
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _copied ? '✅' : '📋',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _copied ? 'Nusxalandi!' : 'Nusxalash',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _copied
                                          ? AppColors.success
                                          : AppColors.primary,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _shareCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('📤', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ulashish',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Timer info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⏱️', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kod 10 daqiqa ichida amal qiladi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vaqt tugagandan so\'ng yangi kod yaratiladi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
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

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 Qanday ulash kerak?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildStep('1', 'Farzandingiz telefonida Qadamcha ilovasini oching'),
                          _buildStep('2', '"Farzandim uchun" tugmasini bosing'),
                          _buildStep('3', 'QR kodni skanerlang yoki oila kodini kiriting'),
                          _buildStep('4', 'Qurilma muvaffaqiyatli ulangan!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
