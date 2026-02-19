import 'dart:async';
import 'package:sms_autofill/sms_autofill.dart';

/// SMS OTP Auto-fill xizmati
/// Android SMS Retriever API orqali ruxsatsiz avtomatik kodni o'qiydi.
class SmsAutoFillService {
  final SmsAutoFill _smsAutoFill = SmsAutoFill();
  StreamSubscription? _subscription;

  /// App signing hash — backend SMS ga qo'shilishi kerak
  Future<String> getAppSignature() async {
    return await _smsAutoFill.getAppSignature;
  }

  /// SMS tinglashni boshlash
  /// [onCodeReceived] — 6 xonali kod topilganda chaqiriladi
  Future<void> listenForSms({
    required void Function(String code) onCodeReceived,
  }) async {
    await _smsAutoFill.listenForCode();
    
    _subscription = SmsAutoFill().code.listen((String message) {
      // SMS matnidan 6 xonali kodni ajratish
      final code = _extractCode(message);
      if (code != null) {
        onCodeReceived(code);
      }
    });
  }

  /// SMS matnidan 6 xonali raqamli kodni ajratish
  String? _extractCode(String message) {
    final regex = RegExp(r'\b(\d{6})\b');
    final match = regex.firstMatch(message);
    return match?.group(1);
  }

  /// Tinglashni to'xtatish — dispose da chaqirish kerak
  void dispose() {
    _subscription?.cancel();
    SmsAutoFill().unregisterListener();
  }
}
