import 'package:dio/dio.dart';
import 'dart:io' show File;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/api_error.dart';

class ApiService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenRefreshRetryFlag = '__token_refresh_retry__';
  static const String _tokenSkipAuthRefreshFlag = '__skip_auth_refresh__';

  // Global refresh lock (queue): aynı anda tek refresh
  static Future<void>? _refreshInFlight;

  static String _requiredEnv(String key) {
    final fromEnv = dotenv.env[key];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;
    throw StateError('$key is not set. Provide it via .env or --dart-define.');
  }

  static String get baseUrl => _requiredEnv('API_BASE_URL');

  static int _requiredEnvInt(String key) {
    final raw = _requiredEnv(key);
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw StateError('$key is not a valid integer: $raw');
    }
    return parsed;
  }
  
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
      baseUrl: baseUrl,
        connectTimeout: Duration(
          milliseconds: _requiredEnvInt('API_CONNECT_TIMEOUT_MS'),
        ),
        receiveTimeout: Duration(
          milliseconds: _requiredEnvInt('API_RECEIVE_TIMEOUT_MS'),
        ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      ),
    );
    
    // Authentication interceptor - her istekte token ekle
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // SharedPreferences'tan token'ı al
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString(_accessTokenKey);
        
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final opts = error.requestOptions;

        // 401 -> access token expired/invalid: refresh + retry (global standard)
        if (status == 401) {
          final alreadyRetried = opts.extra[_tokenRefreshRetryFlag] == true;
          final skipRefresh = opts.extra[_tokenSkipAuthRefreshFlag] == true;

          // Refresh endpoint / login gibi çağrılarda refresh yapma (sonsuz döngü önle)
          final path = opts.path;
          final isAuthPath = path.startsWith('/users/login') ||
              path.startsWith('/users/refresh') ||
              path.startsWith('/users/register');

          if (!alreadyRetried && !skipRefresh && !isAuthPath) {
            try {
              await _queueTokenRefresh();

              // Yeni access token ile isteği tekrar dene
              final prefs = await SharedPreferences.getInstance();
              final newAccessToken = prefs.getString(_accessTokenKey);
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
              }
              opts.extra[_tokenRefreshRetryFlag] = true;

              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {
              // Refresh başarısız -> aşağıdaki handler.next ile standart hata akışı
            }
          }
        }

        return handler.next(error);
      },
    ));
    
    // Interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Tek standart: Token yenileme. 401 interceptor ve AuthController bu metodu kullanır.
  static Future<void> refreshTokens() async {
    await _queueTokenRefresh();
  }

  static Future<void> _queueTokenRefresh() async {
    // Halihazırda refresh varsa onu bekle
    final current = _refreshInFlight;
    if (current != null) {
      return await current;
    }

    final refreshFuture = _refreshTokensInternal();
    _refreshInFlight = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      // refresh tamamlanınca lock'u bırak
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }
  }

  static Future<void> _refreshTokensInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException(statusCode: 401, message: 'Refresh token bulunamadı');
    }

    // Auth refresh isteği: interceptor kullanmadan
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: _requiredEnvInt('API_CONNECT_TIMEOUT_MS')),
        receiveTimeout: Duration(milliseconds: _requiredEnvInt('API_RECEIVE_TIMEOUT_MS')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final resp = await dio.post(
        '/users/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          extra: {_tokenSkipAuthRefreshFlag: true},
        ),
      );

      final data = resp.data;
      if (data is! Map) {
        throw ApiException(statusCode: 401, message: 'Refresh cevabı geçersiz');
      }

      final newAccess = data['access_token']?.toString();
      final newRefresh = data['refresh_token']?.toString();
      if (newAccess == null || newAccess.isEmpty) {
        throw ApiException(statusCode: 401, message: 'Yeni access token alınamadı');
      }

      await prefs.setString(_accessTokenKey, newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, newRefresh);
      }
    } on DioException catch (e) {
      // Refresh başarısız -> tokenları temizle ki UI login’e düşebilsin
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      throw mapDioError(e);
    }
  }
  
  // Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Generic POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Generic DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Upload file
  Future<Response> uploadFile(String path, dynamic file, {String? fieldName, String? filename}) async {
    try {
      MultipartFile multipartFile;
      
      // Hem web hem mobil için XFile kullan
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename ?? file.name,
        );
      } else if (file is PlatformFile) {
        if (file.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            file.bytes!,
            filename: filename ?? file.name,
          );
        } else if (!kIsWeb && file.path != null) {
          multipartFile = await MultipartFile.fromFile(file.path!);
        } else {
          throw Exception('PlatformFile için geçerli veri veya yol bulunamadı');
        }
      } else if (!kIsWeb && file is File) {
        // Sadece mobil/desktop için File desteği
        multipartFile = await MultipartFile.fromFile(file.path);
      } else {
        throw Exception('Dosya tipi desteklenmiyor: ${file.runtimeType}');
      }
      
      final formData = FormData.fromMap({
        fieldName ?? 'file': multipartFile,
      });
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
