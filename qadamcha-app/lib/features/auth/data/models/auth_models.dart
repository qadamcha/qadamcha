import '../../domain/entities/user_entity.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    required super.name,
    required super.role,
    super.avatar,
    super.lastLoginAt,
    required super.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'parent',
      avatar: json['avatar'],
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role,
      'avatar': avatar,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  User toEntity() => User(
    id: id,
    phone: phone,
    name: name,
    role: role,
    avatar: avatar,
    lastLoginAt: lastLoginAt,
    createdAt: createdAt,
  );
}

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
  });
  
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}

class OtpResultModel extends OtpResult {
  const OtpResultModel({
    required super.isNewUser,
    required super.verifiedToken,
    required super.message,
  });
  
  factory OtpResultModel.fromJson(Map<String, dynamic> json) {
    return OtpResultModel(
      isNewUser: json['isNewUser'] ?? false,
      verifiedToken: json['verifiedToken'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
