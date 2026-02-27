import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  
  ApiClient({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.addAll([
      _RetryInterceptor(_dio),
      _AuthInterceptor(_storage, _dio),
      _LoggingInterceptor(),
    ]);
  }
  
  Dio get dio => _dio;
  
  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(message: 'Internet xatosi: Serverga ulanib bo\'lmadi. Internet aloqangizni tekshiring.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map ? data['message'] : 'Xatolik yuz berdi';
        
        if (statusCode == 401) {
          return UnauthorizedException(message: message ?? 'Tizimga qayta kiring');
        }
        return ServerException(
          message: message ?? 'Serverda xatolik',
          statusCode: statusCode,
        );
      default:
        return ServerException(message: e.message ?? 'Noma\'lum xatolik');
    }
  }
}

// Auth Interceptor - Token management
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  
  _AuthInterceptor(this._storage, this._dio);
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Token ni qo'shish
    // Faqat quyidagi yo'llarga token QO'SHILMAYDI (public endpoints):
    final publicPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/send-otp',
      '/auth/verify-otp',
      '/auth/refresh', // Refresh body orqali yuboriladi
    ];

    final isPublicPath = publicPaths.any((path) => options.path.contains(path));

    if (!isPublicPath) {
      final token = await _storage.read(key: StorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Refresh token so'rovining o'zi 401 bo'lsa, qayta urinmaymiz (loop oldini olish)
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // Token yangilashga urinish
      try {
        final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
        if (refreshToken != null) {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          
          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
            
            // Token rotation: yangi refresh token ni ham saqlash
            final newRefreshToken = response.data['refreshToken'];
            if (newRefreshToken != null) {
              await _storage.write(key: StorageKeys.refreshToken, value: newRefreshToken);
            }
            
            // Asl so'rovni qaytadan yuborish
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneRequest = await _dio.fetch(err.requestOptions);
            return handler.resolve(cloneRequest);
          }
        }
      } catch (_) {
        // Refresh ham ishlamadi - logout qilish kerak
      }
    }
    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✖ ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}

// Retry Interceptor — ulanish xatosida avtomatik qayta urinish
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 1);

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Faqat ulanish xatolarida qayta urinish
    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!isRetryable) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount >= _maxRetries) {
      print('⚠ Retry limit reached for ${err.requestOptions.path}');
      return handler.next(err);
    }

    print('🔄 Retry ${retryCount + 1}/$_maxRetries: ${err.requestOptions.path}');
    await Future.delayed(_retryDelay);

    try {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
