import 'package:easy_localization/easy_localization.dart';

/// Custom API exception classes
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(message: message ?? 'error.network'.tr(), errorCode: 'NETWORK_ERROR');
}

class TimeoutException extends ApiException {
  TimeoutException({String? message})
      : super(message: message ?? 'error.timeout'.tr(), errorCode: 'TIMEOUT');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(message: message ?? 'error.unauthorized'.tr(), statusCode: 401, errorCode: 'UNAUTHORIZED');
}

class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(message: message ?? 'error.forbidden'.tr(), statusCode: 403, errorCode: 'FORBIDDEN');
}

class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(message: message ?? 'error.not_found'.tr(), statusCode: 404, errorCode: 'NOT_FOUND');
}

class ServerException extends ApiException {
  ServerException({String? message})
      : super(message: message ?? 'error.server'.tr(), statusCode: 500, errorCode: 'SERVER_ERROR');
}
