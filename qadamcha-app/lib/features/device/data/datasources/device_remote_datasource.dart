import '../../../../core/network/api_client.dart';
import '../models/device_model.dart';

abstract class DeviceRemoteDataSource {
  Future<String> generateFamilyCode();
  Future<DeviceModel> linkDevice({
    required String familyCode,
    required String childId,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  });
  Future<List<DeviceModel>> getDevices();
  Future<void> deleteDevice(String deviceId);
  Future<void> sendHeartbeat();
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiClient _client;
  
  DeviceRemoteDataSourceImpl(this._client);
  
  @override
  Future<String> generateFamilyCode() async {
    final response = await _client.post('/devices/generate-code');
    return response.data['familyCode'] ?? response.data['code'] ?? '';
  }
  
  @override
  Future<DeviceModel> linkDevice({
    required String familyCode,
    required String childId,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  }) async {
    final response = await _client.post('/devices/link', data: {
      'familyCode': familyCode,
      'childId': childId,
      'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceType != null) 'deviceType': deviceType,
    });
    return DeviceModel.fromJson(response.data['device'] ?? response.data);
  }
  
  @override
  Future<List<DeviceModel>> getDevices() async {
    final response = await _client.get('/devices');
    final List<dynamic> data = response.data['devices'] ?? response.data ?? [];
    return data.map((json) => DeviceModel.fromJson(json)).toList();
  }
  
  @override
  Future<void> deleteDevice(String deviceId) async {
    await _client.delete('/devices/$deviceId');
  }
  
  @override
  Future<void> sendHeartbeat() async {
    await _client.post('/devices/heartbeat');
  }
}
