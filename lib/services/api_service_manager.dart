// lib/services/api_service_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/bot_badge_state.dart';
import '../models/message_model.dart';
import '../models/session_info.dart';

enum ServiceType {
  mcpAgent, // Python Enhanced MCP Agent (8081)
  externalApi, // Ekibin FastAPI servisi (8083)
}

class ApiServiceManager {
  // Servis URL'leri
  static const String _mcpAgentUrl = 'http://10.0.2.2:8081';
  static const String _externalApiUrl = 'http://10.0.2.2:8083';

  // Zaman aşımı ayarları
  static const Duration _timeout =
      Duration(seconds: 35); // /chat gibi ağır istekler
  static const Duration _healthTimeout = Duration(seconds: 5); // /health vb.

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

  /// Tek giriş noktası: uygun servise yönlendir
  static Future<UniversalChatResponse> sendMessage({
    required String message,
    int? customerNo, // ✅ takım1 ise 17953063 gelecek; yoksa null olabilir
    String? sessionId,
    ServiceType? serviceType,
  }) async {
    final target = serviceType ?? _currentService;
    switch (target) {
      case ServiceType.mcpAgent:
        return _sendToMcpAgent(message, customerNo, sessionId);
      case ServiceType.externalApi:
        // Dış serviste eski sözleşme userId bekliyorsa istersen burada map’leyebilirsin.
        return _sendToExternalApi(message, customerNo, sessionId);
    }
  }

  /// MCP Agent (Python - 8081) /chat
  /// Beklenen body: { "message": string, "customerNo": int? }
  static Future<UniversalChatResponse> _sendToMcpAgent(
    String message,
    int? customerNo,
    String? sessionId,
  ) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/chat');
      final body = <String, dynamic>{
        'message': message,
        if (customerNo != null)
          'customerNo': customerNo, // ✅ agent_api.py ile uyumlu
        if (sessionId != null || _currentSessionId != null)
          'sessionId': sessionId ??
              _currentSessionId, // agent şu an bunu kullanmıyor; opsiyonel
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
        if (data['success'] == true) {
          final reply = (data['response'] ?? '').toString();
          final ts = data['timestamp'] ?? DateTime.now().toIso8601String();

          // agent_api şu an session_id / message_id döndürmüyor -> lokal üret
          final sid = _currentSessionId ?? sessionId ?? '';
          final mid = _generateMessageId();

          return UniversalChatResponse(
            success: true,
            message: reply,
            sessionId: sid,
            messageId: mid,
            serviceType: ServiceType.mcpAgent,
            badgeState: _determineBadgeFromContent(reply),
            timestamp: ts,
          );
        } else {
          throw ApiException(data['error']?['message'] ?? 'MCP Agent hatası');
        }
      } else {
        throw ApiException('MCP Agent sunucu hatası: ${resp.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('MCP Agent bağlantı hatası: $e');
    }
  }

  /// External FastAPI (ekip - 8083) /chat
  /// Not: Bu servis farklı sözleşme kullanıyorsa ihtiyaca göre düzenle.
  static Future<UniversalChatResponse> _sendToExternalApi(
    String message,
    int? customerNo,
    String? sessionId,
  ) async {
    try {
      final url = Uri.parse('$_externalApiUrl/chat');
      final body = {
        // Ekip sözleşmesi user_id isteyebilir; customerNo’yu oraya mapliyoruz:
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
          await _startMcpAgentSession(newId); // Python'da yok → no-op/deneme
          break;
        case ServiceType.externalApi:
          await _startExternalApiSession(newId); // varsa kullanılacak
          break;
      }
      _currentSessionId = newId;
      return newId;
    } catch (_) {
      _currentSessionId = newId; // localde set et
      return newId;
    }
  }

  static Future<void> _startMcpAgentSession(String sessionId) async {
    // Python Enhanced MCP Agent'ta 'session/new' yok. No-op deneme bırakıldı.
    try {
      final url = Uri.parse('$_mcpAgentUrl/session/new');
      final resp = await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'session_id': sessionId}))
          .timeout(_healthTimeout);
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        // no-op
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ MCP Agent session başlatma hatası (opsiyonel): $e');
    }
  }

  static Future<void> _startExternalApiSession(String sessionId) async {
    try {
      final url = Uri.parse('$_externalApiUrl/session/new');
      final resp = await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'session_id': sessionId}))
          .timeout(_healthTimeout);
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        // no-op
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ External API session başlatma hatası: $e');
    }
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
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Session temizleme hatası: $e');
    } finally {
      _currentSessionId = null;
    }
  }

  // Python gerçek endpoint'i: POST /sessions/{session_id}/close (bizde yok; no-op)
  static Future<void> _clearMcpAgentSession(String sessionId) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/sessions/$sessionId/close');
      await http.post(url).timeout(_healthTimeout);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ MCP Agent session temizleme hatası: $e');
    }
  }

  static Future<void> _clearExternalApiSession(String sessionId) async {
    try {
      final url = Uri.parse('$_externalApiUrl/session/$sessionId/clear');
      await http.delete(url).timeout(_healthTimeout);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ External API session temizleme hatası: $e');
    }
  }

  /// Oturum listesi
  // Python gerçek endpoint'i: GET /sessions/{user_id} (bizde yok; no-op)
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
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Session listesi alma hatası: $e');
    }
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
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ MCP Agent sessions listesi hatası: $e');
      return [];
    }
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
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ External API sessions listesi hatası: $e');
      return [];
    }
  }

  /// Sağlık kontrolleri
  static Future<bool> checkExternalApiHealth() async {
    try {
      final url = Uri.parse('$_externalApiUrl/health');
      final resp = await http.get(url).timeout(_healthTimeout);
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('❌ External API Health Check Hatası: $e');
      return false;
    }
  }

  static Future<bool> checkMcpAgentHealth() async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/health');
      final resp = await http.get(url).timeout(_healthTimeout);
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('❌ MCP Agent Health Check Hatası: $e');
      return false;
    }
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

  // Yardımcılar
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
