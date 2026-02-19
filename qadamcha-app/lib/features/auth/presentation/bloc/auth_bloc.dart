import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../data/datasources/auth_local_datasource.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final AuthLocalDataSource? localDataSource;
  
  AuthBloc({required this.repository, this.localDataSource}) : super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetAuthEvent>(_onReset);
    on<ResetPinEvent>(_onResetPin);
    on<AuthVerifyPinEvent>(_onVerifyPin);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ChangePinEvent>(_onChangePin);
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await repository.isLoggedIn();
    
    if (isLoggedIn) {
      final result = await repository.getCachedUser();
      if (result.isRight()) {
        final user = result.getOrElse(() => null);
        if (user != null) {
          // Device mode ni lokal cache dan olish
          String deviceMode = 'parent';
          if (localDataSource != null) {
            deviceMode = await localDataSource!.getDeviceMode();
          }
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            deviceMode: deviceMode,
          ));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      } else {
        // User cache yo'q — lekin token bor bo'lishi mumkin
        // Token refresh qilib ko'ramiz
        final refreshResult = await repository.refreshToken();
        refreshResult.fold(
          (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
          (_) => emit(state.copyWith(status: AuthStatus.authenticated)),
        );
      }
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }
  
  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, phone: event.phone));
    
    final result = await repository.sendOtp(event.phone, purpose: event.purpose);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (message) => emit(state.copyWith(
        status: AuthStatus.otpSent,
        phone: event.phone,
      )),
    );
  }
  
  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.verifyOtp(event.phone, event.code);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (otpResult) => emit(state.copyWith(
        status: AuthStatus.otpVerified,
        isNewUser: otpResult.isNewUser,
        verifiedToken: otpResult.verifiedToken,
      )),
    );
  }
  
  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.register(
      phone: event.phone,
      name: event.name,
      pin: event.pin,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.registered,
        user: user,
      )),
    );
  }
  
  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.login(
      phone: event.phone,
      pin: event.pin,
      deviceId: event.deviceId,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: data.$1,
        deviceMode: data.$3,
      )),
    );
  }
  
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    // Logout oldidan barcha monitoring datani backend'ga sync qilish
    LocalMonitoringService.instance.syncAllToBackend();
    
    await repository.logout();
    
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
  
  void _onReset(
    ResetAuthEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState());
  }
  
  Future<void> _onResetPin(
    ResetPinEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.resetPin(
      phone: event.phone,
      newPin: event.newPin,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (message) => emit(state.copyWith(
        status: AuthStatus.pinReset,
      )),
    );
  }

  Future<void> _onVerifyPin(
    AuthVerifyPinEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.verifyPin(event.pin);
    
    result.fold(
      (failure) {
        // Agar 401 yoki AuthFailure bo'lsa, demak sessiya tugagan
        if (failure is AuthFailure || (failure is ServerFailure && failure.statusCode == 401)) {
          emit(state.copyWith(
            status: AuthStatus.unauthenticated, // Login sahifasiga o'tkazish
            errorMessage: 'Sessiya vaqti tugadi. Qayta kiring.',
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      (_) => emit(state.copyWith(
        status: AuthStatus.pinVerified,
      )),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.updateProfile(name: event.name);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> _onChangePin(
    ChangePinEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    // Avval joriy PIN ni tekshirish
    final verifyResult = await repository.verifyPin(event.currentPin);
    
    final verified = verifyResult.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Joriy PIN noto\'g\'ri',
        ));
        return false;
      },
      (_) => true,
    );
    
    if (!verified) return;
    
    // Yangi PIN ni o'rnatish
    final resetResult = await repository.resetPin(
      phone: event.phone,
      newPin: event.newPin,
    );
    
    resetResult.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: AuthStatus.authenticated,
      )),
    );
  }
}
