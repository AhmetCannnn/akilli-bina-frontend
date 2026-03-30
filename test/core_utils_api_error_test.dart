import 'package:belediye_otomasyon/core/utils/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDioError', () {
    test('uses backend detail when available', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'detail': 'Backend hatası'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = mapDioError(dioError);

      expect(apiError.message, 'Backend hatası');
      expect(apiError.statusCode, 400);
    });

    test('falls back to timeout message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiError = mapDioError(dioError);

      expect(
        apiError.message,
        'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
    });
  });

  group('humanizeError', () {
    test('returns ApiException message', () {
      final err = ApiException(message: 'Özel hata');
      expect(humanizeError(err), 'Özel hata');
    });

    test('returns toString for other errors', () {
      final err = Exception('X');
      expect(humanizeError(err), err.toString());
    });
  });
}


