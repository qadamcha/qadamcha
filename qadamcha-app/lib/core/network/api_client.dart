import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      if (kDebugMode) _LoggingInterceptor(),
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

// Auth Interceptor - Token management with refresh lock
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  
  // Concurrent refresh ni oldini olish uchun lock
  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];
  
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

    // PIN verify 401 = "PIN noto'g'ri", token bilan bog'liq EMAS
    // Bu yerda refresh qilmasdan, xatoni to'g'ridan-to'g'ri qaytarish kerak
    if (err.requestOptions.path.contains('/auth/verify-pin')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // Agar allaqachon refresh qilinayotgan bo'lsa — navbatga qo'shamiz
      if (_isRefreshing) {
        try {
          final newToken = await _waitForRefresh();
          if (newToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final cloneRequest = await _dio.fetch(err.requestOptions);
            return handler.resolve(cloneRequest);
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Queued request retry failed: $e');
        }
        return handler.next(err);
      }

      // Birinchi 401 — biz refresh qilamiz
      _isRefreshing = true;
      if (kDebugMode) print('🔄 Token refresh boshlandi...');
      
      try {
        final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
        if (refreshToken == null) {
          if (kDebugMode) print('⚠️ Refresh token topilmadi! Storage da yo\'q.');
        }
        if (refreshToken != null) {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          
          if (response.statusCode == 200 && response.data['accessToken'] != null) {
            if (kDebugMode) print('✅ Token refresh muvaffaqiyatli!');
            final newAccessToken = response.data['accessToken'] as String;
            await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
            
            // Token rotation: yangi refresh token ni ham saqlash
            final newRefreshToken = response.data['refreshToken'];
            if (newRefreshToken != null) {
              await _storage.write(key: StorageKeys.refreshToken, value: newRefreshToken as String);
            }
            
            // Navbatdagi barcha so'rovlarga yangi tokenni berish
            _resolveQueue(newAccessToken);
            
            // Asl so'rovni qaytadan yuborish
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneRequest = await _dio.fetch(err.requestOptions);
            return handler.resolve(cloneRequest);
          } else {
            if (kDebugMode) print('⚠️ Token refresh javobi noto\'g\'ri: statusCode=${response.statusCode}, data=${response.data}');
          }
        }
        // Refresh ishlamadi — navbatni reject qilish
        if (kDebugMode) print('⚠️ Token refresh muvaffaqiyatsiz.');
        _rejectQueue();
      } catch (e) {
        if (kDebugMode) print('⚠️ Token refresh xatosi: $e');
        _rejectQueue();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  /// Refresh tugashini kutish (navbatdagi so'rovlar uchun)
  Future<String?> _waitForRefresh() {
    final completer = Completer<String?>();
    _requestQueue.add(_QueuedRequest(completer));
    return completer.future;
  }

  /// Navbatdagi barcha so'rovlarga yangi tokenni berish
  void _resolveQueue(String token) {
    for (final req in _requestQueue) {
      req.completer.complete(token);
    }
    _requestQueue.clear();
  }

  /// Navbatdagi barcha so'rovlarni reject qilish
  void _rejectQueue() {
    for (final req in _requestQueue) {
      req.completer.complete(null);
    }
    _requestQueue.clear();
  }
}

class _QueuedRequest {
  final Completer<String?> completer;
  _QueuedRequest(this.completer);
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.path}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✖ ${err.response?.statusCode} ${err.requestOptions.path}');
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
      if (kDebugMode) print('⚠ Retry limit reached for ${err.requestOptions.path}');
      return handler.next(err);
    }

    if (kDebugMode) print('🔄 Retry ${retryCount + 1}/$_maxRetries: ${err.requestOptions.path}');
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
