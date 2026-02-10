class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException({
    this.message = 'Serverda xatolik yuz berdi',
    this.statusCode,
  });
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException({
    this.message = 'Internet aloqasi yo\'q',
  });
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  const CacheException({
    this.message = 'Ma\'lumotlar saqlanmagan',
  });
  
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  
  const UnauthorizedException({
    this.message = 'Autentifikatsiya talab qilinadi',
  });
  
  @override
  String toString() => message;
}

class TokenExpiredException implements Exception {
  final String message;
  
  const TokenExpiredException({
    this.message = 'Token muddati tugadi',
  });
  
  @override
  String toString() => message;
}
