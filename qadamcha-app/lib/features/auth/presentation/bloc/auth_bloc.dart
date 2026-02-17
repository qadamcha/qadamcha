import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  
  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetAuthEvent>(_onReset);
    on<ResetPinEvent>(_onResetPin);
    on<AuthVerifyPinEvent>(_onVerifyPin);
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await repository.isLoggedIn();
    
    if (isLoggedIn) {
      final result = await repository.getCachedUser();
      result.fold(
        (failure) async {
          // User cache yo'q — lekin token bor bo'lishi mumkin
          // Token refresh qilib ko'ramiz
          final refreshResult = await repository.refreshToken();
          refreshResult.fold(
            (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
            (_) => emit(state.copyWith(status: AuthStatus.authenticated)),
          );
        },
        (user) {
          if (user != null) {
            emit(state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
            ));
          } else {
            emit(state.copyWith(status: AuthStatus.unauthenticated));
          }
        },
      );
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
      )),
    );
  }
  
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
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
}
