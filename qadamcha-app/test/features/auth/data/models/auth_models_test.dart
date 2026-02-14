import 'package:flutter_test/flutter_test.dart';
import 'package:qadamcha_app/features/auth/data/models/auth_models.dart';

void main() {
  group('UserModel', () {
    final testJson = {
      'id': '123',
      'phone': '+998901234567',
      'name': 'Test User',
      'role': 'parent',
      'avatar': null,
      'lastLoginAt': '2024-01-01T00:00:00.000Z',
      'createdAt': '2024-01-01T00:00:00.000Z',
    };

    test('fromJson to\'g\'ri parse qilishi kerak', () {
      final user = UserModel.fromJson(testJson);

      expect(user.id, '123');
      expect(user.phone, '+998901234567');
      expect(user.name, 'Test User');
      expect(user.role, 'parent');
      expect(user.avatar, isNull);
      expect(user.lastLoginAt, isNotNull);
      expect(user.createdAt, isNotNull);
    });

    test('fromJson _id ni ham qabul qilishi kerak', () {
      final json = {...testJson, '_id': '456'};
      json.remove('id');
      final user = UserModel.fromJson(json);
      expect(user.id, '456');
    });

    test('fromJson bo\'sh fieldlar uchun default qiymatlar', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.phone, '');
      expect(user.name, '');
      expect(user.role, 'parent');
    });

    test('toJson to\'g\'ri serialize qilishi kerak', () {
      final user = UserModel.fromJson(testJson);
      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['phone'], '+998901234567');
      expect(json['name'], 'Test User');
      expect(json['role'], 'parent');
    });

    test('toEntity User entity qaytarishi kerak', () {
      final user = UserModel.fromJson(testJson);
      final entity = user.toEntity();

      expect(entity.id, user.id);
      expect(entity.phone, user.phone);
      expect(entity.name, user.name);
      expect(entity.isParent, true);
      expect(entity.isChild, false);
    });
  });

  group('AuthTokensModel', () {
    test('fromJson to\'g\'ri parse qilishi kerak', () {
      final tokens = AuthTokensModel.fromJson({
        'accessToken': 'access123',
        'refreshToken': 'refresh456',
      });

      expect(tokens.accessToken, 'access123');
      expect(tokens.refreshToken, 'refresh456');
    });

    test('bo\'sh json uchun bo\'sh string qaytarishi kerak', () {
      final tokens = AuthTokensModel.fromJson({});
      expect(tokens.accessToken, '');
      expect(tokens.refreshToken, '');
    });
  });

  group('OtpResultModel', () {
    test('fromJson to\'g\'ri parse qilishi kerak', () {
      final result = OtpResultModel.fromJson({
        'isNewUser': true,
        'verifiedToken': 'token123',
        'message': 'Kirish uchun PIN kiriting',
      });

      expect(result.isNewUser, true);
      expect(result.verifiedToken, 'token123');
      expect(result.message, 'Kirish uchun PIN kiriting');
    });

    test('mavjud user uchun isNewUser false bo\'lishi kerak', () {
      final result = OtpResultModel.fromJson({
        'isNewUser': false,
        'verifiedToken': 'token',
        'message': 'Ro\'yxatdan o\'ting',
      });

      expect(result.isNewUser, false);
    });

    test('default qiymatlar to\'g\'ri bo\'lishi kerak', () {
      final result = OtpResultModel.fromJson({});
      expect(result.isNewUser, false);
      expect(result.verifiedToken, '');
      expect(result.message, '');
    });
  });
}
