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
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  final tUser = User(
    id: '1',
    phone: '+998901234567',
    name: 'Test',
    role: 'parent',
    createdAt: DateTime(2024, 1, 1),
  );

  final tTokens = AuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  final tOtpResult = OtpResult(
    isNewUser: true,
    verifiedToken: 'token',
    message: 'Ro\'yxatdan o\'ting',
  );

  group('CheckAuthStatusEvent', () {
    blocTest<AuthBloc, AuthState>(
      'authenticated bo\'lishi kerak agar login bo\'lgan bo\'lsa',
      build: () {
        when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockRepo.getCachedUser())
            .thenAnswer((_) async => Right(tUser));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(CheckAuthStatusEvent()),
      expect: () => [
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'unauthenticated bo\'lishi kerak agar login bo\'lmagan bo\'lsa',
      build: () {
        when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(CheckAuthStatusEvent()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('SendOtpEvent', () {
    blocTest<AuthBloc, AuthState>(
      'otpSent holatiga o\'tishi kerak muvaffaqiyatda',
      build: () {
        when(() => mockRepo.sendOtp(any()))
            .thenAnswer((_) async => const Right('OTP yuborildi'));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const SendOtpEvent('+998901234567')),
      expect: () => [
        const AuthState(status: AuthStatus.loading, phone: '+998901234567'),
        const AuthState(status: AuthStatus.otpSent, phone: '+998901234567'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'error holatiga o\'tishi kerak xatoda',
      build: () {
        when(() => mockRepo.sendOtp(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const SendOtpEvent('+998901234567')),
      expect: () => [
        const AuthState(status: AuthStatus.loading, phone: '+998901234567'),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.error),
      ],
    );
  });

  group('VerifyOtpEvent', () {
    blocTest<AuthBloc, AuthState>(
      'otpVerified holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.verifyOtp(any(), any()))
            .thenAnswer((_) async => Right(tOtpResult));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const VerifyOtpEvent(phone: '+998901234567', code: '123456'),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.otpVerified)
            .having((s) => s.isNewUser, 'isNewUser', true),
      ],
    );
  });

  group('LoginEvent', () {
    blocTest<AuthBloc, AuthState>(
      'authenticated holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.login(
          phone: any(named: 'phone'),
          pin: any(named: 'pin'),
          deviceId: any(named: 'deviceId'),
        )).thenAnswer((_) async => Right((tUser, tTokens)));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoginEvent(
        phone: '+998901234567',
        pin: '1234',
        deviceId: 'device1',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'error holatiga o\'tishi kerak noto\'g\'ri PIN da',
      build: () {
        when(() => mockRepo.login(
          phone: any(named: 'phone'),
          pin: any(named: 'pin'),
          deviceId: any(named: 'deviceId'),
        )).thenAnswer((_) async => const Left(AuthFailure('PIN noto\'g\'ri')));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoginEvent(
        phone: '+998901234567',
        pin: '0000',
        deviceId: 'device1',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.error),
      ],
    );
  });

  group('LogoutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'unauthenticated holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.logout())
            .thenAnswer((_) async => const Right(null));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LogoutEvent()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('ResetAuthEvent', () {
    blocTest<AuthBloc, AuthState>(
      'initial holatiga qaytishi kerak',
      build: () => AuthBloc(repository: mockRepo),
      act: (bloc) => bloc.add(ResetAuthEvent()),
      expect: () => [const AuthState()],
    );
  });

  group('ResetPinEvent', () {
    blocTest<AuthBloc, AuthState>(
      'pinReset holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.resetPin(
          phone: any(named: 'phone'),
          newPin: any(named: 'newPin'),
        )).thenAnswer((_) async => const Right('PIN yangilandi'));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const ResetPinEvent(phone: '+998901234567', newPin: '5678'),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.pinReset),
      ],
    );
  });

  group('AuthVerifyPinEvent', () {
    blocTest<AuthBloc, AuthState>(
      'pinVerified holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.verifyPin(any()))
            .thenAnswer((_) async => const Right(null));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthVerifyPinEvent('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.pinVerified),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'unauthenticated holatiga o\'tishi kerak sessiya tugaganda',
      build: () {
        when(() => mockRepo.verifyPin(any()))
            .thenAnswer((_) async => const Left(AuthFailure('Unauthorized')));
        return AuthBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthVerifyPinEvent('1234')),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
    );
  });
}
