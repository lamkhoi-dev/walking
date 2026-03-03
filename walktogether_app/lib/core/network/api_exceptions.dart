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
  NetworkException({String message = 'Không có kết nối mạng'})
      : super(message: message, errorCode: 'NETWORK_ERROR');
}

class TimeoutException extends ApiException {
  TimeoutException({String message = 'Kết nối quá thời gian. Vui lòng thử lại.'})
      : super(message: message, errorCode: 'TIMEOUT');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'Phiên đăng nhập đã hết hạn'})
      : super(message: message, statusCode: 401, errorCode: 'UNAUTHORIZED');
}

class ForbiddenException extends ApiException {
  ForbiddenException({String message = 'Bạn không có quyền thực hiện thao tác này'})
      : super(message: message, statusCode: 403, errorCode: 'FORBIDDEN');
}

class NotFoundException extends ApiException {
  NotFoundException({String message = 'Không tìm thấy dữ liệu'})
      : super(message: message, statusCode: 404, errorCode: 'NOT_FOUND');
}

class ServerException extends ApiException {
  ServerException({String message = 'Lỗi hệ thống. Vui lòng thử lại sau.'})
      : super(message: message, statusCode: 500, errorCode: 'SERVER_ERROR');
}
