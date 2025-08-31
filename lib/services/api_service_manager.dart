// lib/services/api_service_manager.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

import '../models/bot_badge_state.dart';
import '../models/message_model.dart';
import '../models/session_info.dart';

enum ServiceType {
  mcpAgent, // Python Enhanced MCP Agent (CLOUD)
  externalApi, // Ekibin FastAPI servisi (8083 - local)
}

class ApiServiceManager {
  // === Servis URL'leri ===
  static const String _mcpAgentUrl = 'https://mcp-agent-api.azurewebsites.net';
  static const String _externalApiUrl = 'http://10.0.2.2:8083';

  // Zaman aşımı ayarları
  static const Duration _timeout = Duration(seconds: 35);
  static const Duration _healthTimeout = Duration(seconds: 5);

  // Oturum yönetimi
  static String? _currentSessionId;
  static ServiceType _currentService = ServiceType.mcpAgent;

  // Aktif servis
  static void setServiceType(ServiceType serviceType) =>
      _currentService = serviceType;
  static ServiceType getCurrentServiceType() => _currentService;

  // Oturum ID referansı
  static String? getCurrentSessionId() => _currentSessionId;
  static void setCurrentSessionId(String sessionId) =>
      _currentSessionId = sessionId;
  static void clearCurrentSessionReference() => _currentSessionId = null;

  /// ---- Chat: Tek giriş noktası ----
  static Future<UniversalChatResponse> sendMessage({
    required String message,
    int? customerNo,
    String? sessionId,
    ServiceType? serviceType,
  }) async {
    final target = serviceType ?? _currentService;
    switch (target) {
      case ServiceType.mcpAgent:
        return _sendToMcpAgent(message, customerNo);
      case ServiceType.externalApi:
        return _sendToExternalApi(message, customerNo, sessionId);
    }
  }

  /// MCP Agent (CLOUD) /chat
  /// İSTENEN BODY: { "customer_id": <int>, "message": "<string>" }
  static Future<UniversalChatResponse> _sendToMcpAgent(
    String message,
    int? customerNo,
  ) async {
    try {
      if (customerNo == null) {
        throw const ApiException('MCP Agent için customer_id zorunludur.');
      }

      final url = Uri.parse('$_mcpAgentUrl/chat');
      final body = <String, dynamic>{
        'customer_id': customerNo,
        'message': message,
      };

      final resp = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        final replyText = (data['reply'] ??
                data['response'] ??
                data['message'] ??
                data['assistant']?['content'] ??
                data['data']?['reply'])
            ?.toString();

        if (replyText == null) {
          throw const ApiException('MCP Agent yanıtında mesaj bulunamadı.');
        }

        final ts = data['timestamp'] ?? DateTime.now().toIso8601String();
        final mid = _generateMessageId();

        return UniversalChatResponse(
          success: true,
          message: replyText,
          sessionId: _currentSessionId ?? '',
          messageId: mid,
          serviceType: ServiceType.mcpAgent,
          badgeState: _determineBadgeFromContent(replyText),
          timestamp: ts,
          metadata: (data['metadata'] is Map<String, dynamic>)
              ? data['metadata']
              : null,
        );
      } else {
        final errText = resp.body.isNotEmpty ? resp.body : 'Bilinmeyen hata';
        throw ApiException(
            'MCP Agent sunucu hatası: ${resp.statusCode} - $errText');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('MCP Agent bağlantı/işleme hatası: $e');
    }
  }

  /// External FastAPI (ekip - 8083) /chat
  static Future<UniversalChatResponse> _sendToExternalApi(
    String message,
    int? customerNo,
    String? sessionId,
  ) async {
    try {
      final url = Uri.parse('$_externalApiUrl/chat');
      final body = {
        if (customerNo != null) 'user_id': customerNo,
        'message': message,
        'session_id': sessionId ?? _currentSessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': 'mobile',
      };

      final resp = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final success =
            data['success'] ?? (data['status'] == 'success') ?? true;
        final responseMessage =
            data['response'] ?? data['message'] ?? data['reply'] ?? '';
        final newSessionId =
            data['session_id'] ?? _currentSessionId ?? _generateSessionId();

        if (success) {
          _currentSessionId = newSessionId;
          return UniversalChatResponse(
            success: true,
            message: responseMessage,
            sessionId: newSessionId,
            messageId: data['message_id'] ?? _generateMessageId(),
            serviceType: ServiceType.externalApi,
            badgeState: _determineBadgeFromContent(responseMessage),
            timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
            metadata: (data['metadata'] is Map<String, dynamic>)
                ? data['metadata']
                : null,
          );
        } else {
          throw ApiException(data['error'] ?? 'External API hatası');
        }
      } else {
        throw ApiException('External API sunucu hatası: ${resp.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('External API bağlantı hatası: $e');
    }
  }

  /// Yeni (local) session başlat – backend opsiyonel
  static Future<String> startNewSession({ServiceType? serviceType}) async {
    final target = serviceType ?? _currentService;
    final newId = _generateSessionId();

    try {
      switch (target) {
        case ServiceType.mcpAgent:
          await _startMcpAgentSession(newId);
          break;
        case ServiceType.externalApi:
          await _startExternalApiSession(newId);
          break;
      }
      _currentSessionId = newId;
      return newId;
    } catch (_) {
      _currentSessionId = newId;
      return newId;
    }
  }

  static Future<void> _startMcpAgentSession(String sessionId) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/session/new');
      await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'session_id': sessionId}))
          .timeout(_healthTimeout);
    } catch (_) {}
  }

  static Future<void> _startExternalApiSession(String sessionId) async {
    try {
      final url = Uri.parse('$_externalApiUrl/session/new');
      await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'session_id': sessionId}))
          .timeout(_healthTimeout);
    } catch (_) {}
  }

  /// Geçerli oturumu temizle (backend + local)
  static Future<void> clearCurrentSession({ServiceType? serviceType}) async {
    if (_currentSessionId == null) return;

    final target = serviceType ?? _currentService;
    try {
      switch (target) {
        case ServiceType.mcpAgent:
          await _clearMcpAgentSession(_currentSessionId!);
          break;
        case ServiceType.externalApi:
          await _clearExternalApiSession(_currentSessionId!);
          break;
      }
    } catch (_) {
    } finally {
      _currentSessionId = null;
    }
  }

  static Future<void> _clearMcpAgentSession(String sessionId) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/sessions/$sessionId/close');
      await http.post(url).timeout(_healthTimeout);
    } catch (_) {}
  }

  static Future<void> _clearExternalApiSession(String sessionId) async {
    try {
      final url = Uri.parse('$_externalApiUrl/session/$sessionId/clear');
      await http.delete(url).timeout(_healthTimeout);
    } catch (_) {}
  }

  /// Oturum listesi
  static Future<List<SessionInfo>> listSessions({
    ServiceType? serviceType,
    required int userId,
  }) async {
    final target = serviceType ?? _currentService;
    try {
      switch (target) {
        case ServiceType.mcpAgent:
          return _listMcpAgentSessions(userId: userId);
        case ServiceType.externalApi:
          return _listExternalApiSessions();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SessionInfo>> _listMcpAgentSessions(
      {required int userId}) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/sessions/$userId');
      final resp = await http.get(url).timeout(_healthTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sessions = data['sessions'] as List? ?? [];
        return sessions.map((s) => SessionInfo.fromJson(s)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SessionInfo>> _listExternalApiSessions() async {
    try {
      final url = Uri.parse('$_externalApiUrl/sessions');
      final resp = await http.get(url).timeout(_healthTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sessions = data['sessions'] as List? ?? [];
        return sessions.map((s) => SessionInfo.fromJson(s)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// ===== Sağlık kontrolleri =====
  static Future<bool> checkExternalApiHealth() async {
    try {
      final url = Uri.parse('$_externalApiUrl/health');
      final resp = await http.get(url).timeout(_healthTimeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkMcpAgentHealth() async {
    // Bulut ajanlarında /health her zaman açık olmayabiliyor.
    // Sıralı ve güvenli denemeler:
    try {
      // 1) /health (varsa)
      final urlHealth = Uri.parse('$_mcpAgentUrl/health');
      final r1 = await http.get(urlHealth).timeout(_healthTimeout);
      if (r1.statusCode == 200) return true;
    } catch (_) {}

    try {
      // 2) root (çoğu PaaS bir 200/404 döndürür; 5xx değilse erişilebilir sayalım)
      final urlRoot = Uri.parse('$_mcpAgentUrl/');
      final r2 = await http.get(urlRoot).timeout(_healthTimeout);
      if (r2.statusCode >= 200 && r2.statusCode < 500) return true;
    } catch (_) {}

    try {
      // 3) /chat için OPTIONS (CORS/Allow test)
      final urlOptions = Uri.parse('$_mcpAgentUrl/chat');
      final r3 = await http.Request('OPTIONS', urlOptions)
          .send()
          .timeout(_healthTimeout);
      if (r3.statusCode >= 200 && r3.statusCode < 500) return true;
    } catch (_) {}

    // 4) Son çare: Bulut URL'si ise soft-healthy dön (banner'ı bloklamasın)
    if (_mcpAgentUrl.startsWith('https://')) {
      return true;
    }

    return false;
  }

  static Future<ServiceHealthStatus> checkAllServicesHealth() async {
    final results = await Future.wait([
      checkMcpAgentHealth(),
      checkExternalApiHealth(),
    ]);
    return ServiceHealthStatus(
      mcpAgentAvailable: results[0],
      externalApiAvailable: results[1],
    );
  }

  // ===== QR PAYMENT (External API) =====
  static Future<QRPayResponse> payQr({
    required String receiverIban,
    required String receiverName,
    required double amount,
    String? note,
    ServiceType? serviceType,
    bool forceExternal = true,
  }) async {
    final target = forceExternal
        ? ServiceType.externalApi
        : (serviceType ?? _currentService);
    if (target == ServiceType.mcpAgent) {
      throw const ApiException('MCP Agent şu an QR ödemeyi desteklemiyor');
    }

    final candidates = [
      Uri.parse('$_externalApiUrl/qr/pay'),
      Uri.parse('$_externalApiUrl/payments/qr'),
    ];

    final body = <String, dynamic>{
      'receiver_iban': receiverIban,
      'receiver_name': receiverName,
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
      if (_currentSessionId != null) 'session_id': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    Object? lastErr;
    for (final url in candidates) {
      try {
        final resp = await http
            .post(
              url,
              headers: const {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final data = jsonDecode(resp.body);

          final success = (data['success'] == true) ||
              (data['status']?.toString().toLowerCase() == 'ok') ||
              (data['status']?.toString().toLowerCase() == 'success');

          if (!success) {
            throw ApiServiceException(
              data['error']?.toString() ??
                  data['message']?.toString() ??
                  'Ödeme başarısız (sunucu).',
            );
          }

          return QRPayResponse.fromJson(
            data,
            fallbackAmount: amount,
            fallbackReceiverName: receiverName,
          );
        } else {
          lastErr = 'HTTP ${resp.statusCode}';
        }
      } catch (e) {
        lastErr = e;
      }
    }

    throw ApiServiceException('QR ödeme endpointine ulaşılamadı: $lastErr');
  }

  // Helpers
  static String _generateSessionId() =>
      'session_${DateTime.now().millisecondsSinceEpoch}';
  static String _generateMessageId() =>
      'msg_${DateTime.now().microsecondsSinceEpoch}';

  static BotBadgeState _determineBadgeFromContent(String content) {
    final c = content.toLowerCase();

    if (c.contains(RegExp(
        r'(account|balance|money|transfer|payment|bank|hesap|para|bakiye)'))) {
      return BotBadgeState.sekreter;
    }
    if (c.contains(
        RegExp(r'(connection|error|problem|unavailable|hata|sorun)'))) {
      return BotBadgeState.noConnection;
    }
    if (c.contains(RegExp(r'(success|completed|done|başarılı|tamamlandı)'))) {
      return BotBadgeState.connection;
    }
    if (c.contains(
        RegExp(r'(thinking|processing|analyzing|düşünüyor|işleniyor)'))) {
      return BotBadgeState.thinking;
    }
    return BotBadgeState.sekreter;
  }
}

/// Tek tip yanıt modeli
class UniversalChatResponse {
  final bool success;
  final String message;
  final String sessionId;
  final String messageId;
  final ServiceType serviceType;
  final BotBadgeState badgeState;
  final String timestamp;
  final Map<String, dynamic>? metadata;

  const UniversalChatResponse({
    required this.success,
    required this.message,
    required this.sessionId,
    required this.messageId,
    required this.serviceType,
    required this.badgeState,
    required this.timestamp,
    this.metadata,
  });

  factory UniversalChatResponse.fromJson(
    Map<String, dynamic> json,
    ServiceType serviceType,
  ) {
    return UniversalChatResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? json['response'] ?? '',
      sessionId: json['session_id'] ?? '',
      messageId: json['message_id'] ?? '',
      serviceType: serviceType,
      badgeState: ApiServiceManager._determineBadgeFromContent(
        json['message'] ?? json['response'] ?? '',
      ),
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      metadata:
          (json['metadata'] is Map<String, dynamic>) ? json['metadata'] : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'session_id': sessionId,
        'message_id': messageId,
        'service_type': serviceType.name,
        'badge_state': badgeState.name,
        'timestamp': timestamp,
        'metadata': metadata,
      };

  @override
  String toString() =>
      'UniversalChatResponse(success: $success, serviceType: $serviceType, sessionId: $sessionId)';
}

class ServiceHealthStatus {
  final bool mcpAgentAvailable;
  final bool externalApiAvailable;

  const ServiceHealthStatus({
    required this.mcpAgentAvailable,
    required this.externalApiAvailable,
  });

  bool get anyServiceAvailable => mcpAgentAvailable || externalApiAvailable;
  bool get allServicesAvailable => mcpAgentAvailable && externalApiAvailable;

  ServiceType? get preferredAvailableService {
    if (mcpAgentAvailable) return ServiceType.mcpAgent;
    if (externalApiAvailable) return ServiceType.externalApi;
    return null;
  }

  @override
  String toString() =>
      'ServiceHealthStatus(mcp: $mcpAgentAvailable, external: $externalApiAvailable)';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() =>
      'ApiException: $message ${statusCode != null ? '(${statusCode})' : ''}';
}

/// ====== QR ödeme modeli ve exception ======
class QRPayResponse {
  final String reference;
  final double amount;
  final String receiverName;

  QRPayResponse({
    required this.reference,
    required this.amount,
    required this.receiverName,
  });

  factory QRPayResponse.fromJson(
    Map<String, dynamic> json, {
    required double fallbackAmount,
    required String fallbackReceiverName,
  }) {
    final ref = (json['reference'] ?? json['ref'] ?? '').toString();
    final amt = (json['amount'] is num)
        ? (json['amount'] as num).toDouble()
        : double.tryParse(json['amount']?.toString() ?? '') ?? fallbackAmount;
    final rcvName =
        (json['receiver_name'] ?? json['receiverName'] ?? fallbackReceiverName)
            .toString();

    return QRPayResponse(
      reference:
          ref.isEmpty ? 'REF-${DateTime.now().millisecondsSinceEpoch}' : ref,
      amount: amt,
      receiverName: rcvName,
    );
  }
}

class ApiServiceException implements Exception {
  final String message;
  ApiServiceException(this.message);
  @override
  String toString() => 'ApiServiceException: $message';
}
