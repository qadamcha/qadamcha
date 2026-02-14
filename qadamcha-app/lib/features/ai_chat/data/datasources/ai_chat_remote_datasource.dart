import '../../../../core/network/api_client.dart';

abstract class AiChatRemoteDataSource {
  Future<String> sendMessage({
    required String message,
    String? childId,
  });

  Future<bool> checkStatus();
}

class AiChatRemoteDataSourceImpl implements AiChatRemoteDataSource {
  final ApiClient _apiClient;

  AiChatRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> sendMessage({
    required String message,
    String? childId,
  }) async {
    final data = <String, dynamic>{'message': message};
    if (childId != null) data['childId'] = childId;

    final response = await _apiClient.post(
      '/ai/chat',
      data: data,
    );

    final body = response.data;
    if (body is Map && body['success'] == true) {
      return body['message'] as String;
    }

    return body is Map
        ? (body['message'] as String? ?? 'Javob olib bo\'lmadi')
        : 'Javob olib bo\'lmadi';
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
