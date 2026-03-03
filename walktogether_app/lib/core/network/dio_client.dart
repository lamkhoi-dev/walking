import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService;

  DioClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storageService, _dio),
      if (kDebugMode) LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    ]);
  }

  Dio get dio => _dio;

  // === HTTP METHODS ===

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.put(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.patch(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  ApiException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        return _handleResponseError(e.response);
      default:
        return ApiException(
          message: e.message ?? 'Đã xảy ra lỗi không xác định',
          statusCode: e.response?.statusCode,
        );
    }
  }

  ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return ServerException();
    }

    final data = response.data;
    final message = data is Map ? (data['message'] ?? 'Lỗi') : 'Lỗi';
    final errorMap = data is Map && data['error'] is Map ? data['error'] as Map : null;
    final errorCode = errorMap?['code'];

    switch (response.statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ApiException(message: message, statusCode: 409, errorCode: errorCode);
      case 422:
        return ApiException(message: message, statusCode: 422, errorCode: 'VALIDATION_ERROR', details: errorMap?['details']);
      case 429:
        return ApiException(message: 'Quá nhiều request. Vui lòng thử lại sau.', statusCode: 429, errorCode: 'RATE_LIMIT');
      default:
        return ServerException(message: message);
    }
  }
}

/// Auth Interceptor - adds Bearer token and handles token refresh
class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._storageService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _storageService.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Try refresh
        final response = await _dio.post(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}), // Don't send expired token
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newToken = response.data['data']['accessToken'];
          final newRefresh = response.data['data']['refreshToken'];

          await _storageService.saveTokens(
            accessToken: newToken,
            refreshToken: newRefresh,
          );

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed, clear tokens
        await _storageService.clearAll();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
