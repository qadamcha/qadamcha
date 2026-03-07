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

      // Backend success: false qaytarsa — aniq xabarni uzatish
      final errorText = body is Map
          ? ((body['message'] as String?) ?? 'Javob olib bo\'lmadi')
          : 'Javob olib bo\'lmadi';
      throw Exception(errorText);
    } on DioException catch (e) {
      // CancelToken — qayta tashlash (bloc da tutiladi)
      if (CancelToken.isCancel(e)) {
        rethrow;
      }
      // ApiClient DioException ni ServerException/NetworkException ga
      // o'giradi, shuning uchun bu yerga faqat cancel keladi.
      // Boshqa DioException lar uchun ham rethrow qilamiz.
      rethrow;
    } catch (e) {
      // ApiClient dan kelgan ServerException, NetworkException
      // yoki backend success:false Exception — hammasini qayta tashlash
      // Bloc da aniq xabar ko'rsatiladi
      rethrow;
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
