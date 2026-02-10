import 'package:dio/dio.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/core/network/api_client.dart';
import 'package:qadamcha_app/features/content/data/models/content_model.dart';

abstract class ContentRemoteDataSource {
  Future<List<ContentModel>> getContents({
    String? type,
    String? category,
    int? age,
    int page = 1,
    int limit = 20,
  });

  Future<ContentModel> getContentById(String id);
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final ApiClient apiClient;

  ContentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ContentModel>> getContents({
    String? type,
    String? category,
    int? age,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get(
        '/content',
        queryParameters: {
          if (type != null) 'type': type,
          if (category != null) 'category': category,
          if (age != null) 'age': age,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> contentsJson = response.data['contents'];
        return contentsJson.map((json) => ContentModel.fromJson(json)).toList();
      } else {
        throw ServerFailure(response.data['message'] ?? 'Unknown error');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ContentModel> getContentById(String id) async {
    try {
      final response = await apiClient.get('/content/$id');

      if (response.data['success'] == true) {
        return ContentModel.fromJson(response.data['content']);
      } else {
        throw ServerFailure(response.data['message'] ?? 'Unknown error');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
