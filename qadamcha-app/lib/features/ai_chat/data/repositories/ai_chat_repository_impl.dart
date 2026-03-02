import 'package:dio/dio.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/ai_chat_remote_datasource.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiChatRemoteDataSource _remoteDataSource;

  AiChatRepositoryImpl({required AiChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<(String, int)> sendMessage({
    required String message,
    String? childId,
    List<Map<String, String>>? history,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _remoteDataSource.sendMessage(
        message: message,
        childId: childId,
        history: history,
        cancelToken: cancelToken,
      );
    } on DioException {
      // CancelToken — qayta tashlash
      rethrow;
    } catch (e) {
      // Barcha boshqa xatolarni qayta tashlash (bloc da tutiladi)
      rethrow;
    }
  }

  @override
  Future<bool> checkStatus() async {
    try {
      return await _remoteDataSource.checkStatus();
    } catch (_) {
      return false;
    }
  }
}
