import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/auth/domain/entities/user_entity.dart';
import 'package:qadamcha_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:qadamcha_app/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepository;

  final tUser = User(
    id: 'user-1',
    phone: '+998901234567',
    name: 'Test User',
    role: 'parent',
    createdAt: DateTime(2024, 1, 1),
  );

  final tOtpResult = OtpResult(
    isNewUser: true,
    verifiedToken: 'verified-token-123',
    message: 'OTP tasdiqlandi',
  );

  final tTokens = AuthTokens(
    accessToken: 'access-token-123',
    refreshToken: 'refresh-token-123',
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthState with initial status', () {
    expect(authBloc.state.status, AuthStatus.initial);
    expect(authBloc.state.user, null);
  });

  // =====================================================
  // CheckAuthStatusEvent
  // =====================================================
  group('CheckAuthStatusEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit authenticated when user is logged in',
      build: () {
        when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockRepository.getCachedUser())
            .thenAnswer((_) async => Right(tUser));
        // refreshToken fallback uchun
        when(() => mockRepository.refreshToken())
            .thenAnswer((_) async => const Right('new-token'));
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckAuthStatusEvent()),
      expect: () => [
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit unauthenticated when user is not logged in',
      build: () {
        when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckAuthStatusEvent()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit unauthenticated when getCachedUser fails',
      build: () {
        when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockRepository.getCachedUser())
            .thenAnswer((_) async => const Left(CacheFailure()));
        // Token ham expire bo'ldi — unauthenticated ga o'tkazish kerak
        when(() => mockRepository.refreshToken())
            .thenAnswer((_) async => const Left(TokenExpiredFailure()));
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckAuthStatusEvent()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  // =====================================================
  // SendOtpEvent
  // =====================================================
  group('SendOtpEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit otpSent on success',
      build: () {
        when(() => mockRepository.sendOtp('+998901234567'))
            .thenAnswer((_) async => const Right('OTP yuborildi'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SendOtpEvent('+998901234567')),
      expect: () => [
        const AuthState(
          status: AuthStatus.loading,
          phone: '+998901234567',
        ),
        const AuthState(
          status: AuthStatus.otpSent,
          phone: '+998901234567',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit error on failure',
      build: () {
        when(() => mockRepository.sendOtp('+998901234567'))
            .thenAnswer((_) async => const Left(ServerFailure('SMS xatosi')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SendOtpEvent('+998901234567')),
      expect: () => [
        const AuthState(
          status: AuthStatus.loading,
          phone: '+998901234567',
        ),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'SMS xatosi',
          phone: '+998901234567',
        ),
      ],
    );
  });

  // =====================================================
  // VerifyOtpEvent
  // =====================================================
  group('VerifyOtpEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit otpVerified with isNewUser=true',
      build: () {
        when(() => mockRepository.verifyOtp('+998901234567', '123456'))
            .thenAnswer((_) async => Right(tOtpResult));
        return authBloc;
      },
      act: (bloc) => bloc.add(const VerifyOtpEvent(
        phone: '+998901234567',
        code: '123456',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.otpVerified,
          isNewUser: true,
          verifiedToken: 'verified-token-123',
        ),
      ],
    );
  });

  // =====================================================
  // LoginEvent
  // =====================================================
  group('LoginEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit authenticated on success',
      build: () {
        when(() => mockRepository.login(
              phone: '+998901234567',
              pin: '1234',
              deviceId: 'device-1',
            )).thenAnswer((_) async => Right((tUser, tTokens)));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginEvent(
        phone: '+998901234567',
        pin: '1234',
        deviceId: 'device-1',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit error on wrong PIN',
      build: () {
        when(() => mockRepository.login(
              phone: '+998901234567',
              pin: '9999',
              deviceId: 'device-1',
            )).thenAnswer(
            (_) async => const Left(AuthFailure('PIN noto\'g\'ri')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginEvent(
        phone: '+998901234567',
        pin: '9999',
        deviceId: 'device-1',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'PIN noto\'g\'ri',
        ),
      ],
    );
  });

  // =====================================================
  // RegisterEvent
  // =====================================================
  group('RegisterEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit registered on success',
      build: () {
        when(() => mockRepository.register(
              phone: '+998901234567',
              name: 'Test User',
              pin: '1234',
            )).thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const RegisterEvent(
        phone: '+998901234567',
        name: 'Test User',
        pin: '1234',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.registered, user: tUser),
      ],
    );
  });

  // =====================================================
  // LogoutEvent
  // =====================================================
  group('LogoutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit unauthenticated',
      build: () {
        when(() => mockRepository.logout())
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutEvent()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  // =====================================================
  // ResetPinEvent
  // =====================================================
  group('ResetPinEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit pinReset on success',
      build: () {
        when(() => mockRepository.resetPin(
              phone: '+998901234567',
              newPin: '5678',
            )).thenAnswer((_) async => const Right('PIN yangilandi'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const ResetPinEvent(
        phone: '+998901234567',
        newPin: '5678',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.pinReset),
      ],
    );
  });

  // =====================================================
  // AuthVerifyPinEvent
  // =====================================================
  group('AuthVerifyPinEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should emit pinVerified on success',
      build: () {
        when(() => mockRepository.verifyPin('1234'))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthVerifyPinEvent('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.pinVerified),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit unauthenticated on AuthFailure (session expired)',
      build: () {
        when(() => mockRepository.verifyPin('1234'))
            .thenAnswer((_) async => const Left(AuthFailure('Sessiya tugadi')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthVerifyPinEvent('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sessiya vaqti tugadi. Qayta kiring.',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit error on generic failure',
      build: () {
        when(() => mockRepository.verifyPin('1234')).thenAnswer(
            (_) async => const Left(ServerFailure('Server xatosi')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthVerifyPinEvent('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Server xatosi',
        ),
      ],
    );
  });

  // =====================================================
  // ResetAuthEvent
  // =====================================================
  group('ResetAuthEvent', () {
    blocTest<AuthBloc, AuthState>(
      'should reset state to initial',
      build: () => authBloc,
      act: (bloc) => bloc.add(ResetAuthEvent()),
      expect: () => [
        const AuthState(),
      ],
    );
  });
}
