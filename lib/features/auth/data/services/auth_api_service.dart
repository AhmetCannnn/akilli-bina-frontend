import '../../../../core/services/api_service.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  /// Kullanıcı kaydı
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    final response = await _apiService.post(
      '/users/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Kullanıcı girişi
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/users/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Kullanıcı bilgilerini getir (token gerekli)
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final response = await _apiService.get('/users/me');
    return Map<String, dynamic>.from(response.data);
  }

  /// Kullanıcı bilgilerini güncelle (token gerekli)
  Future<Map<String, dynamic>> updateCurrentUser({
    String? email,
  }) async {
    final response = await _apiService.put(
      '/users/me',
      data: {
        if (email != null) 'email': email,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Çıkış yap (token gerekli)
  Future<void> logout(String accessToken) async {
    await _apiService.post('/users/logout');
  }

  /// Şifre değiştir (token gerekli)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      '/users/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Davet linki ile hesap tamamlama
  Future<Map<String, dynamic>> completeInvite({
    required String token,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/users/complete-invite',
      data: {
        'token': token,
        'password': password,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }
}

