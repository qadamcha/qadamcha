import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qadamcha_app/core/errors/exceptions.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:qadamcha_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qadamcha_app/features/auth/data/models/auth_models.dart';
import 'package:qadamcha_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockLocalDataSource extends Mock implements AuthLocalDataSource {}

class FakeAuthTokensModel extends Fake implements AuthTokensModel {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late AuthRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(FakeAuthTokensModel());
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repo = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
    );
  });

  final tUserModel = UserModel(
    id: '1',
    phone: '+998901234567',
    name: 'Test',
    role: 'parent',
    createdAt: DateTime(2024, 1, 1),
  );

  const tTokens = AuthTokensModel(
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  group('sendOtp', () {
    test('muvaffaqiyatli OTP yuborish', () async {
      when(() => mockRemote.sendOtp(any()))
          .thenAnswer((_) async => 'OTP yuborildi');

      final result = await repo.sendOtp('+998901234567');

      expect(result, const Right('OTP yuborildi'));
    });

    test('NetworkException → NetworkFailure', () async {
      when(() => mockRemote.sendOtp(any()))
          .thenThrow(const NetworkException());

      final result = await repo.sendOtp('+998901234567');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Right qaytmasligi kerak'),
      );
    });

    test('ServerException → ServerFailure', () async {
      when(() => mockRemote.sendOtp(any())).thenThrow(
        const ServerException(message: 'Server xato', statusCode: 500),
      );

      final result = await repo.sendOtp('+998901234567');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server xato');
        },
        (_) => fail('Right qaytmasligi kerak'),
      );
    });
  });

  group('login', () {
    test('muvaffaqiyatli login — tokenlar cache qilinishi kerak', () async {
      when(() => mockRemote.login(
            phone: any(named: 'phone'),
            pin: any(named: 'pin'),
            deviceId: any(named: 'deviceId'),
            deviceName: any(named: 'deviceName'),
            deviceType: any(named: 'deviceType'),
          )).thenAnswer((_) async => (tUserModel, tTokens));
      when(() => mockLocal.cacheTokens(any())).thenAnswer((_) async {});
      when(() => mockLocal.cacheUser(any())).thenAnswer((_) async {});
      when(() => mockLocal.setLoggedIn(any())).thenAnswer((_) async {});

      final result = await repo.login(
        phone: '+998901234567',
        pin: '1234',
        deviceId: 'device1',
      );

      expect(result.isRight(), true);
      verify(() => mockLocal.cacheTokens(tTokens)).called(1);
      verify(() => mockLocal.cacheUser(tUserModel)).called(1);
      verify(() => mockLocal.setLoggedIn(true)).called(1);
    });

    test('UnauthorizedException → AuthFailure', () async {
      when(() => mockRemote.login(
            phone: any(named: 'phone'),
            pin: any(named: 'pin'),
            deviceId: any(named: 'deviceId'),
            deviceName: any(named: 'deviceName'),
            deviceType: any(named: 'deviceType'),
          )).thenThrow(const UnauthorizedException(message: 'PIN noto\'g\'ri'));

      final result = await repo.login(
        phone: '+998901234567',
        pin: '0000',
        deviceId: 'device1',
      );

      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Right qaytmasligi kerak'),
      );
    });
  });

  group('logout', () {
    test('muvaffaqiyatli logout — cache tozalanishi kerak', () async {
      when(() => mockRemote.logout()).thenAnswer((_) async {});
      when(() => mockLocal.clearCache()).thenAnswer((_) async {});

      final result = await repo.logout();

      expect(result, const Right(null));
      verify(() => mockLocal.clearCache()).called(1);
    });

    test('server xatosida ham local cache tozalanishi kerak', () async {
      when(() => mockRemote.logout()).thenThrow(Exception('Server xato'));
      when(() => mockLocal.clearCache()).thenAnswer((_) async {});

      final result = await repo.logout();

      expect(result, const Right(null));
      verify(() => mockLocal.clearCache()).called(1);
    });
  });

  group('refreshToken', () {
    test('yangi tokenlar saqlashi kerak (rotation)', () async {
      when(() => mockLocal.getCachedTokens())
          .thenAnswer((_) async => tTokens);
      when(() => mockRemote.refreshToken(any())).thenAnswer(
        (_) async => const AuthTokensModel(
          accessToken: 'new_access',
          refreshToken: 'new_refresh',
        ),
      );
      when(() => mockLocal.cacheTokens(any())).thenAnswer((_) async {});

      final result = await repo.refreshToken();

      expect(result, const Right('new_access'));
      verify(() => mockLocal.cacheTokens(any())).called(1);
    });

    test('token yo\'q bo\'lsa TokenExpiredFailure', () async {
      when(() => mockLocal.getCachedTokens()).thenAnswer((_) async => null);

      final result = await repo.refreshToken();

      result.fold(
        (failure) => expect(failure, isA<TokenExpiredFailure>()),
        (_) => fail('Right qaytmasligi kerak'),
      );
    });

    test('UnauthorizedException da cache tozalanishi kerak', () async {
      when(() => mockLocal.getCachedTokens())
          .thenAnswer((_) async => tTokens);
      when(() => mockRemote.refreshToken(any()))
          .thenThrow(const UnauthorizedException());
      when(() => mockLocal.clearCache()).thenAnswer((_) async {});

      final result = await repo.refreshToken();

      result.fold(
        (failure) => expect(failure, isA<TokenExpiredFailure>()),
        (_) => fail('Right qaytmasligi kerak'),
      );
      verify(() => mockLocal.clearCache()).called(1);
    });
  });

  group('verifyPin', () {
    test('muvaffaqiyatli PIN tekshirish', () async {
      when(() => mockRemote.verifyPin(any())).thenAnswer((_) async {});

      final result = await repo.verifyPin('1234');

      expect(result, const Right(null));
    });

    test('ServerException → ServerFailure', () async {
      when(() => mockRemote.verifyPin(any())).thenThrow(
        const ServerException(message: 'PIN noto\'g\'ri', statusCode: 401),
      );

      final result = await repo.verifyPin('0000');

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Right qaytmasligi kerak'),
      );
    });
  });

  group('isLoggedIn', () {
    test('true qaytarishi kerak agar login bo\'lgan bo\'lsa', () async {
      when(() => mockLocal.isLoggedIn()).thenAnswer((_) async => true);

      final result = await repo.isLoggedIn();

      expect(result, true);
    });
  });
}
