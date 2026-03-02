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

    try {
      final response = await _apiClient.post(
        '/ai/chat',
        data: data,
        options: Options(
          // AI javob berishi uchun 90s (backend 60s + network buffer)
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 15),
        ),
        cancelToken: cancelToken,
      );

      final body = response.data;

      // Null yoki noto'g'ri format tekshirish
      if (body == null) {
        throw Exception('Server javob qaytarmadi');
      }

      if (body is Map && body['success'] == true) {
        final text = (body['message'] as String?) ?? '';
        if (text.isEmpty) {
          throw Exception('AI bo\'sh javob qaytardi');
        }
        final tokenCount = (body['tokenCount'] as int?) ?? 0;
        return (text, tokenCount);
      }

      // Backend success: false qaytarsa
      final errorText = body is Map
          ? ((body['message'] as String?) ?? 'Javob olib bo\'lmadi')
          : 'Javob olib bo\'lmadi';
      throw Exception(errorText);
    } on DioException catch (e) {
      // CancelToken — qayta tashlash (bloc da tutiladi)
      if (CancelToken.isCancel(e)) {
        rethrow;
      }

      // Timeout xatosi
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('timeout: AI javob berishi ko\'proq vaqt oldi');
      }

      // Internet xatosi
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('internet: Internet aloqangiz bilan muammo bor');
      }

      // 401 — sessiya tugagan
      if (e.response?.statusCode == 401) {
        throw Exception('Sessiya tugadi. Iltimos, tizimga qayta kiring.');
      }

      // Boshqa server xatolari
      final data = e.response?.data;
      final message = data is Map 
          ? (data['message'] as String?) ?? 'Server xatosi'
          : e.message ?? 'Noma\'lum xatolik';
      throw Exception(message);
    }
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
