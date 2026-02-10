import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phone;
  final String name;
  final String role;
  final String? avatar;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.avatar,
    this.lastLoginAt,
    required this.createdAt,
  });
  
  bool get isParent => role == 'parent';
  bool get isChild => role == 'child';
  
  @override
  List<Object?> get props => [id, phone, name, role, avatar];
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
  
  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class OtpResult extends Equatable {
  final bool isNewUser;
  final String verifiedToken;
  final String message;
  
  const OtpResult({
    required this.isNewUser,
    required this.verifiedToken,
    required this.message,
  });
  
  @override
  List<Object?> get props => [isNewUser, verifiedToken, message];
}
