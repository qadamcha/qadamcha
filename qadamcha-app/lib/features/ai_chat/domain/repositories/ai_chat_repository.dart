/// AI Chat Repository — domain layer interface
abstract class AiChatRepository {
  /// AI ga savol yuborish va javob olish (tarix bilan)
  /// Returns: (javob matni, tokenCount)
  Future<(String, int)> sendMessage({
    required String message,
    String? childId,
    List<Map<String, String>>? history,
  });

  /// AI xizmat holatini tekshirish
  Future<bool> checkStatus();
}
