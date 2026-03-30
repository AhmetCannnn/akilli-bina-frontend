import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:belediye_otomasyon/core/services/api_service.dart';
import '../../data/services/auth_api_service.dart';

part 'auth_provider.g.dart';

/// Token storage keys
const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';
const String _userDataKey = 'user_data';

@riverpod
class AuthController extends _$AuthController {
  final AuthApiService _apiService = AuthApiService();
  SharedPreferences? _prefs;

  @override
  Future<AuthState?> build() async {
    _prefs = await SharedPreferences.getInstance();
    return await _loadAuthState();
  }

  /// Auth state'i yükle (token varsa)
  Future<AuthState?> _loadAuthState() async {
    final accessToken = _prefs?.getString(_accessTokenKey);
    final refreshToken = _prefs?.getString(_refreshTokenKey);
    final userDataStr = _prefs?.getString(_userDataKey);

    if (accessToken != null && refreshToken != null) {
      Map<String, dynamic>? userData;
      if (userDataStr != null) {
        userData = _decodeUserData(userDataStr);
      }
      return AuthState(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: userData,
      );
    }
    return null;
  }

  Map<String, dynamic>? _decodeUserData(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Token'ları kaydet
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    await _prefs?.setString(_accessTokenKey, accessToken);
    await _prefs?.setString(_refreshTokenKey, refreshToken);
    if (userData != null) {
      await _prefs?.setString(_userDataKey, jsonEncode(userData));
    } else {
      await _prefs?.remove(_userDataKey);
    }
    state = AsyncValue.data(AuthState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userData: userData,
    ));
  }

  /// Token'ları temizle
  Future<void> _clearTokens() async {
    await _prefs?.remove(_accessTokenKey);
    await _prefs?.remove(_refreshTokenKey);
    await _prefs?.remove(_userDataKey);
    state = const AsyncValue.data(null);
  }

  /// Kullanıcı kaydı
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    try {
      state = const AsyncValue.loading();
      final userData = await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      
      // Kayıt sonrası otomatik login
      await login(email: email, password: password);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Kullanıcı girişi
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      final accessToken = response['access_token'] as String;
      final refreshToken = response['refresh_token'] as String;

      // Önce tokenları kaydet ki interceptor header ekleyebilsin
      await _saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: null,
      );

      // Kullanıcı bilgilerini al (header interceptor üzerinden eklenecek)
      final userData = await _apiService.getCurrentUser(accessToken);

      await _saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: userData,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Token yenile — tek standart: ApiService.refreshTokens() kullanır
  Future<void> refreshToken() async {
    try {
      await ApiService.refreshTokens();
      state = AsyncValue.data(await _loadAuthState());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        await _clearTokens();
      }
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      final currentState = state.value;
      if (currentState != null && currentState.accessToken.isNotEmpty) {
        await _apiService.logout(currentState.accessToken);
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _clearTokens();
    }
  }

  /// Kullanıcı bilgilerini güncelle
  Future<void> refreshUserData() async {
    try {
      final currentState = state.value;
      if (currentState == null) return;

      final userData = await _apiService.getCurrentUser(currentState.accessToken);
      await _saveTokens(
        accessToken: currentState.accessToken,
        refreshToken: currentState.refreshToken,
        userData: userData,
      );
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
}

/// Auth state model
class AuthState {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic>? userData;

  AuthState({
    required this.accessToken,
    required this.refreshToken,
    this.userData,
  });

  bool get isAuthenticated => accessToken.isNotEmpty;
  
  String? get userId => userData?['id']?.toString();
  String? get userEmail => userData?['email']?.toString();
  String? get userFullName => userData?['full_name']?.toString();
  String? get userRole => userData?['role']?.toString();
}

