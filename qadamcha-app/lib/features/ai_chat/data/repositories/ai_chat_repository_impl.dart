import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/ai_chat_remote_datasource.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiChatRemoteDataSource _remoteDataSource;

  AiChatRepositoryImpl({required AiChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<String> sendMessage({
    required String message,
    String? childId,
  }) {
    return _remoteDataSource.sendMessage(
      message: message,
      childId: childId,
    );
  }

  @override
  Future<bool> checkStatus() {
    return _remoteDataSource.checkStatus();
  }
}
