/// AI Chat Repository — domain layer interface
abstract class AiChatRepository {
  /// AI ga savol yuborish va javob olish
  Future<String> sendMessage({
    required String message,
    String? childId,
  });

  /// AI xizmat holatini tekshirish
  Future<bool> checkStatus();
}
