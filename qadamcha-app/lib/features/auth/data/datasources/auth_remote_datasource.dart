import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<String> sendOtp(String phone, {String? purpose});
  Future<OtpResultModel> verifyOtp(String phone, String code);
  Future<UserModel> register(String phone, String name, String pin);
  Future<(UserModel, AuthTokensModel, String)> login({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  });
  Future<String> refreshToken(String refreshToken);
  Future<void> logout();
  Future<String> resetPin(String phone, String newPin);
  Future<void> verifyPin(String pin);
  Future<String> changePin(String currentPin, String newPin);
  Future<UserModel> updateProfile({required String name});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;
  
  AuthRemoteDataSourceImpl(this._client);
  
  @override
  Future<String> sendOtp(String phone, {String? purpose}) async {
    final response = await _client.post('/auth/send-otp', data: {
      'phone': phone,
      if (purpose != null) 'purpose': purpose,
    });
    return response.data['message'] ?? 'OTP yuborildi';
  }
  
  @override
  Future<OtpResultModel> verifyOtp(String phone, String code) async {
    final response = await _client.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
    });
    return OtpResultModel.fromJson(response.data);
  }
  
  @override
  Future<UserModel> register(String phone, String name, String pin) async {
    final response = await _client.post('/auth/register', data: {
      'phone': phone,
      'name': name,
      'pin': pin,
    });
    return UserModel.fromJson(response.data['user'] ?? response.data);
  }
  
  @override
  Future<(UserModel, AuthTokensModel, String)> login({
    required String phone,
    required String pin,
    required String deviceId,
    String? deviceName,
    String? deviceType,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'phone': phone,
      'pin': pin,
      'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceType != null) 'deviceType': deviceType,
    });
    
    final user = UserModel.fromJson(response.data['user']);
    final tokens = AuthTokensModel.fromJson(response.data);
    final deviceMode = response.data['deviceMode'] as String? ?? 'parent';
    
    return (user, tokens, deviceMode);
  }
  
  @override
  Future<String> refreshToken(String refreshToken) async {
    final response = await _client.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    return response.data['accessToken'];
  }
  
  @override
  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
  
  @override
  Future<String> resetPin(String phone, String newPin) async {
    final response = await _client.post('/auth/reset-pin', data: {
      'phone': phone,
      'newPin': newPin,
    });
    return response.data['message'] ?? 'PIN yangilandi';
  }

  @override
  Future<void> verifyPin(String pin) async {
    await _client.post('/auth/verify-pin', data: {'pin': pin});
  }

  @override
  Future<String> changePin(String currentPin, String newPin) async {
    final response = await _client.put('/user/pin', data: {
      'currentPin': currentPin,
      'newPin': newPin,
    });
    return response.data['message'] ?? 'PIN muvaffaqiyatli o\'zgartirildi';
  }

  @override
  Future<UserModel> updateProfile({required String name}) async {
    final response = await _client.put('/auth/profile', data: {
      'name': name,
    });
    return UserModel.fromJson(response.data['user'] ?? response.data);
  }
}
