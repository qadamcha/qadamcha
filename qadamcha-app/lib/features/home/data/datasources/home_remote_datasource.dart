import '../../../../core/network/api_client.dart';
import '../models/child_model.dart';
import '../models/activity_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<ChildModel>> getChildren();
  Future<ChildModel> getChild(String childId);
  Future<ChildModel> createChild({
    required String name,
    required int age,
    String? gender,
    int? dailyLimit,
  });
  Future<ChildModel> updateChild(String childId, Map<String, dynamic> data);
  Future<void> deleteChild(String childId);
  Future<void> setDailyLimit(String childId, int minutes);
  Future<List<ActivityModel>> getActivities(String childId);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _client;
  
  HomeRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<ChildModel>> getChildren() async {
    final response = await _client.get('/children');
    final List<dynamic> data = response.data['children'] ?? response.data ?? [];
    return data.map((json) => ChildModel.fromJson(json)).toList();
  }
  
  @override
  Future<ChildModel> getChild(String childId) async {
    final response = await _client.get('/children/$childId');
    return ChildModel.fromJson(response.data['child'] ?? response.data);
  }
  
  @override
  Future<ChildModel> createChild({
    required String name,
    required int age,
    String? gender,
    int? dailyLimit,
  }) async {
    final response = await _client.post('/children', data: {
      'name': name,
      'age': age,
      if (gender != null) 'gender': gender,
      if (dailyLimit != null) 'dailyLimit': dailyLimit,
    });
    return ChildModel.fromJson(response.data['child'] ?? response.data);
  }
  
  @override
  Future<ChildModel> updateChild(String childId, Map<String, dynamic> data) async {
    final response = await _client.put('/children/$childId', data: data);
    return ChildModel.fromJson(response.data['child'] ?? response.data);
  }
  
  @override
  Future<void> deleteChild(String childId) async {
    await _client.delete('/children/$childId');
  }
  
  @override
  Future<void> setDailyLimit(String childId, int minutes) async {
    await _client.post('/children/$childId/limit', data: {
      'dailyLimit': minutes,
    });
  }
  
  @override
  Future<List<ActivityModel>> getActivities(String childId) async {
    final response = await _client.get('/children/$childId/activities');
    final List<dynamic> data = response.data['activities'] ?? response.data ?? [];
    return data.map((json) => ActivityModel.fromJson(json)).toList();
  }
}
