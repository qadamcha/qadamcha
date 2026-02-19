import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

abstract class AiChatRemoteDataSource {
  /// AI ga xabar yuborish (tarix bilan)
  /// Returns: (javob matni, tokenCount)
  Future<(String, int)> sendMessage({
    required String message,
    String? childId,
    List<Map<String, String>>? history,
    CancelToken? cancelToken,
  });

  Future<bool> checkStatus();
}

class AiChatRemoteDataSourceImpl implements AiChatRemoteDataSource {
  final ApiClient _apiClient;

  AiChatRemoteDataSourceImpl(this._apiClient);

  @override
  Future<(String, int)> sendMessage({
    required String message,
    String? childId,
    List<Map<String, String>>? history,
    CancelToken? cancelToken,
  }) async {
    final data = <String, dynamic>{'message': message};
    if (childId != null) data['childId'] = childId;
    if (history != null && history.isNotEmpty) data['history'] = history;

    final response = await _apiClient.post(
      '/ai/chat',
      data: data,
      options: Options(
        // AI javob berishi uchun 60s (45s backend + 15s network buffer)
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
      ),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body is Map && body['success'] == true) {
      final text = body['message'] as String;
      final tokenCount = (body['tokenCount'] as int?) ?? 0;
      return (text, tokenCount);
    }

    // Backend success: false qaytarsa — exception tashlash
    final errorText = body is Map
        ? (body['message'] as String? ?? 'Javob olib bo\'lmadi')
        : 'Javob olib bo\'lmadi';
    throw Exception(errorText);
  }

  @override
  Future<bool> checkStatus() async {
    try {
      final response = await _apiClient.get('/ai/status');
      final body = response.data;
      return body is Map && body['configured'] == true;
    } catch (_) {
      return false;
    }
  }
}
