import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/auth_models.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<AuthTokensModel?> getCachedTokens();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<bool> isLoggedIn();
  Future<void> setLoggedIn(bool value);
  
  /// PIN hash'ni lokal saqlash (SHA256)
  Future<void> cachePinHash(String pin);
  
  /// PIN ni lokal tekshirish (server chaqirmasdan)
  Future<bool> verifyPinLocally(String pin);
  
  /// PIN hash'ni o'chirish (logout da)
  Future<void> clearPinHash();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  
  AuthLocalDataSourceImpl({
    FlutterSecureStorage? secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _prefs = prefs;
  
  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    await _secureStorage.write(
      key: StorageKeys.accessToken, 
      value: tokens.accessToken,
    );
    await _secureStorage.write(
      key: StorageKeys.refreshToken, 
      value: tokens.refreshToken,
    );
  }
  
  @override
  Future<AuthTokensModel?> getCachedTokens() async {
    final accessToken = await _secureStorage.read(key: StorageKeys.accessToken);
    final refreshToken = await _secureStorage.read(key: StorageKeys.refreshToken);
    
    if (accessToken == null || refreshToken == null) return null;
    
    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
  
  @override
  Future<void> cacheUser(UserModel user) async {
    await _prefs.setString('cached_user', jsonEncode(user.toJson()));
    await _secureStorage.write(key: StorageKeys.userId, value: user.id);
    await _secureStorage.write(key: StorageKeys.phoneNumber, value: user.phone);
  }
  
  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = _prefs.getString('cached_user');
    if (jsonString == null) return null;
    
    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> clearCache() async {
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
    await _secureStorage.delete(key: StorageKeys.userId);
    await _prefs.remove('cached_user');
    await _prefs.setBool(StorageKeys.isLoggedIn, false);
  }
  
  @override
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }
  
  @override
  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(StorageKeys.isLoggedIn, value);
  }

  /// PIN ni base64 encode qilib FlutterSecureStorage ga saqlash
  /// (FlutterSecureStorage o'zi AES-256 shifrlaydi)
  @override
  Future<void> cachePinHash(String pin) async {
    final encoded = base64Encode(utf8.encode('qadamcha_pin_$pin'));
    await _secureStorage.write(key: StorageKeys.pinHash, value: encoded);
  }

  /// PIN ni lokal tekshirish — server chaqirmasdan, 1ms da
  @override
  Future<bool> verifyPinLocally(String pin) async {
    final savedHash = await _secureStorage.read(key: StorageKeys.pinHash);
    if (savedHash == null) return false; // Hash yo'q — serverda tekshirish kerak
    
    final inputHash = base64Encode(utf8.encode('qadamcha_pin_$pin'));
    return savedHash == inputHash;
  }

  /// PIN hash'ni o'chirish
  @override
  Future<void> clearPinHash() async {
    await _secureStorage.delete(key: StorageKeys.pinHash);
  }
}
