import 'package:smart_auth/smart_auth.dart';

/// SMS OTP Auto-fill xizmati (User Consent API)
/// Foydalanuvchiga SMS dialog ko'rsatib, ruxsat bergandan keyin
/// kodni avtomatik o'qiydi. Hash kerak EMAS.
class SmsAutoFillService {
  final _smartAuth = SmartAuth();

  /// SMS tinglashni boshlash (User Consent API)
  /// Dialog chiqadi → foydalanuvchi ruxsat beradi → kod qaytadi
  Future<void> listenForSms({
    required void Function(String code) onCodeReceived,
  }) async {
    final res = await _smartAuth.getSmsCode(
      useUserConsentApi: true,
    );

    if (res.succeed && res.code != null) {
      onCodeReceived(res.code!);
    }
  }

  /// Tinglashni to'xtatish
  void dispose() {
    _smartAuth.removeSmsListener();
  }
}
