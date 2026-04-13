import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:belediye_otomasyon/core/services/api_service.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/features/issues/presentation/providers/issue_provider.dart';
import 'package:belediye_otomasyon/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Oturum açıkken tek WebSocket; sunucudan gelen kısa olaylarla listeleri yeniler.
///
/// Kopma (ağ, uyku, sunucu restart) sonrası **üstel bekleme** ile yeniden bağlanır.
/// Çıkış veya token değişimi [syncAuth] ile `_sessionGeneration` artırılarak bekleyen
/// yeniden denemeler iptal edilir.
class RealtimeWsClient {
  RealtimeWsClient._();

  static WebSocketChannel? _channel;
  static StreamSubscription<dynamic>? _subscription;
  static String? _lastToken;
  static WidgetRef? _ref;

  /// Kasıtlı çıkış / yeni token ile artırılır; eski stream callback'leri yok sayılır.
  static int _sessionGeneration = 0;

  /// Ardışık başarısız bağlantı / kopma (başarılı [\_connect] sonrası sıfırlanır).
  static int _reconnectAttempt = 0;

  static Timer? _reconnectTimer;

  /// Token **URL'de yok** (production'da nginx erişim logunda JWT görünmesin).
  /// Kimlik doğrulama sunucuda ilk metin mesajı ile yapılır.
  static Uri _buildWsUri() {
    final b = Uri.parse(ApiService.baseUrl);
    return Uri(
      scheme: b.scheme == 'https' ? 'wss' : 'ws',
      host: b.host,
      port: b.hasPort ? b.port : null,
      path: '/ws',
    );
  }

  static void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  static void _cleanupSocketOnly() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Auth durumu değişince [WidgetRef] ile çağrılır (AppShell içindeki listen).
  static void syncAuth(WidgetRef ref, AuthState? auth) {
    _ref = ref;
    if (auth == null) {
      _lastToken = null;
      _sessionGeneration++;
      _cancelReconnectTimer();
      _reconnectAttempt = 0;
      _cleanupSocketOnly();
      return;
    }
    if (_lastToken == auth.accessToken) {
      return;
    }
    _lastToken = auth.accessToken;
    _sessionGeneration++;
    _cancelReconnectTimer();
    _reconnectAttempt = 0;
    _cleanupSocketOnly();
    _connect(ref, auth.accessToken);
  }

  /// Tamamen kapat (ör. test); normalde [syncAuth] null ile çağrılır.
  static void disconnect() {
    _lastToken = null;
    _sessionGeneration++;
    _cancelReconnectTimer();
    _reconnectAttempt = 0;
    _cleanupSocketOnly();
  }

  static void _connect(WidgetRef ref, String token) {
    final genAtSubscribe = _sessionGeneration;
    try {
      final uri = _buildWsUri();
      _channel = WebSocketChannel.connect(uri);
      // İlk çerçeve: JWT sadece TLS payload içinde (query yok).
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{
          'type': 'auth',
          'token': token,
        }),
      );
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _onSocketClosed(genAtSubscribe),
        onDone: () => _onSocketClosed(genAtSubscribe),
        cancelOnError: true,
      );
      _reconnectAttempt = 0;
    } catch (_) {
      if (genAtSubscribe != _sessionGeneration) {
        return;
      }
      _reconnectAttempt++;
      _scheduleReconnectAfterLoss(ref, token, genAtSubscribe);
    }
  }

  static void _onSocketClosed(int genWhenSubscribed) {
    _cleanupSocketOnly();
    if (genWhenSubscribed != _sessionGeneration) {
      return;
    }
    if (_lastToken == null) {
      return;
    }
    // Açık bağlantı koptu: yeni bir yeniden deneme dizisi (ilk gecikme 2s).
    _reconnectAttempt = 0;
    final r = _ref;
    final token = _lastToken;
    if (r == null || token == null) {
      return;
    }
    _scheduleReconnectAfterLoss(r, token, genWhenSubscribed);
  }

  /// Bekleme: 2, 4, 8, 16, 30, 30… saniye (üst sınır 30).
  static void _scheduleReconnectAfterLoss(WidgetRef ref, String token, int gen) {
    _cancelReconnectTimer();
    final delaySec = min(30, 2 << min(_reconnectAttempt, 4));
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      _reconnectTimer = null;
      if (gen != _sessionGeneration) {
        return;
      }
      if (_lastToken != token) {
        return;
      }
      if (_ref != ref) {
        return;
      }
      if (_channel != null) {
        return;
      }
      _connect(ref, token);
    });
  }

  static void _onMessage(dynamic data) {
    final r = _ref;
    if (r == null) {
      return;
    }
    if (data is! String) {
      return;
    }
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final type = map['type']?.toString();
      if (type == null || type == 'connected') {
        return;
      }

      int? buildingId;
      final rawBid = map['building_id'];
      if (rawBid is int) {
        buildingId = rawBid;
      } else if (rawBid != null) {
        buildingId = int.tryParse(rawBid.toString());
      }

      switch (type) {
        case 'maintenance_changed':
          r.invalidate(maintenanceControllerProvider);
          if (buildingId != null) {
            r.invalidate(maintenanceByBuildingProvider(buildingId));
            r.invalidate(maintenanceSummaryProvider(buildingId));
          }
          break;
        case 'issue_changed':
          r.invalidate(issueControllerProvider);
          break;
        default:
          break;
      }
    } catch (_) {
      // JSON değil (ör. pong) — yok say
    }
  }
}
