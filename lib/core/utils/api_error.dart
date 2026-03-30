import 'package:dio/dio.dart';

/// Standard API exception with optional statusCode and details.
class ApiException implements Exception {
  ApiException({
    this.statusCode,
    required this.message,
    this.details,
  });

  final int? statusCode;
  final String message;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Map DioException to a standardized ApiException with readable message.
ApiException mapDioError(DioException e) {
  // Prefer backend-provided message when available
  String? backendMessage;
  final status = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map && data['detail'] != null) {
    backendMessage = data['detail'].toString();
  } else if (data is String && data.trim().isNotEmpty) {
    backendMessage = data.trim();
  }

  // Fallback messages by Dio error type / status code
  final message = backendMessage ??
      () {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
          case DioExceptionType.connectionError:
            return 'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.';
          case DioExceptionType.badResponse:
            return 'Sunucu hatası: $status';
          case DioExceptionType.cancel:
            return 'İstek iptal edildi';
          case DioExceptionType.unknown:
          default:
            return 'Beklenmeyen bir hata oluştu.';
        }
      }();

  return ApiException(
    statusCode: status,
    message: message,
    details: e.response?.data,
  );
}

/// Get user-friendly message from any error.
String humanizeError(Object err) =>
    err is ApiException ? err.message : err.toString();

