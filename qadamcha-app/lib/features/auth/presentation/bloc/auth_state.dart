part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  otpVerified,
  registered,
  pinReset,
  pinVerified,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isNewUser;
  final String? verifiedToken;
  final String? phone;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isNewUser = false,
    this.verifiedToken,
    this.phone,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isNewUser,
    String? verifiedToken,
    String? phone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
      verifiedToken: verifiedToken ?? this.verifiedToken,
      phone: phone ?? this.phone,
    );
  }
  
  @override
  List<Object?> get props => [
    status, 
    user, 
    errorMessage, 
    isNewUser, 
    verifiedToken, 
    phone,
  ];
}
