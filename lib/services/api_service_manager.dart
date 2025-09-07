// lib/services/api_service_manager.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/bot_badge_state.dart';
import '../models/message_model.dart';
import '../models/session_info.dart';

enum ServiceType {
  mcpAgent, // Only MCP Agent is supported
}

class ApiServiceManager {
  // === Service URLs ===
  static const String _mcpAgentUrl = 'https://mcp-agent-api.azurewebsites.net';

  // Timeouts
  static const Duration _timeout = Duration(seconds: 50);
  static const Duration _healthTimeout = Duration(seconds: 5);

  // Session
  static String? _currentSessionId;
  static ServiceType _currentService = ServiceType.mcpAgent;

  static void setServiceType(ServiceType serviceType) =>
      _currentService = serviceType;
  static ServiceType getCurrentServiceType() => _currentService;

  static String? getCurrentSessionId() => _currentSessionId;
  static void setCurrentSessionId(String sessionId) =>
      _currentSessionId = sessionId;
  static void clearCurrentSessionReference() => _currentSessionId = null;

  /// ---- Initialize session at app start ----
  static Future<String> initializeSession() async {
    try {
      final newSessionId = _generateSessionId();
      final url = Uri.parse('$_mcpAgentUrl/session/start');

      final response = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'session_id': newSessionId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentSessionId = newSessionId;
        print('[ApiServiceManager] Session initialized: $newSessionId');
        return newSessionId;
      } else {
        print(
            '[ApiServiceManager] Session init failed: ${response.statusCode}');
        // Fallback to local session if server fails
        _currentSessionId = newSessionId;
        return newSessionId;
      }
    } catch (e) {
      print('[ApiServiceManager] Session init error: $e');
      // Fallback to local session
      final fallbackId = _generateSessionId();
      _currentSessionId = fallbackId;
      return fallbackId;
    }
  }

  /// ---- End session at app close ----
  static Future<void> endSession() async {
    if (_currentSessionId == null) {
      print('[ApiServiceManager] No active session to end');
      return;
    }

    try {
      final url = Uri.parse('$_mcpAgentUrl/session/end');

      final response = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'session_id': _currentSessionId}),
          )
          .timeout(_healthTimeout);

      if (response.statusCode == 200) {
        print(
            '[ApiServiceManager] Session ended successfully: $_currentSessionId');
      } else {
        print('[ApiServiceManager] Session end failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiServiceManager] Session end error: $e');
    } finally {
      _currentSessionId = null;
    }
  }

  /// ---- Chat: single entry point ----
  static Future<UniversalChatResponse> sendMessage({
    required String message,
    required int customerNo,
    String? sessionId,
    ServiceType? serviceType, // kept for compatibility but ignored
  }) async {
    // Use current session ID if not provided
    final activeSessionId = sessionId ?? _currentSessionId;
    if (activeSessionId == null) {
      throw const ApiException('No active session. Please restart the app.');
    }

    return _sendToMcpAgent(message, customerNo, activeSessionId);
  }

  /// MCP Agent (CLOUD) /chat
  /// BODY: { "customer_id": <int>, "message": "<string>", "session_id": "<string>" }
  static Future<UniversalChatResponse> _sendToMcpAgent(
    String message,
    int customerNo,
    String sessionId,
  ) async {
    try {
      final url = Uri.parse('$_mcpAgentUrl/chat');
      final body = <String, dynamic>{
        'customer_id': customerNo,
        'message': message,
        'session_id': sessionId,
      };

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

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));

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
          sessionId: sessionId,
          messageId: mid,
          serviceType: ServiceType.mcpAgent,
          badgeState: _determineBadgeFromContent(replyText),
          timestamp: ts,
          metadata: (data['metadata'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(data['metadata'])
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

  /// Start new session – creates a new session and replaces current one
  static Future<String> startNewSession({ServiceType? serviceType}) async {
    // End current session first
    if (_currentSessionId != null) {
      await endSession();
    }

    // Start new session
    return await initializeSession();
  }

  /// Clear current session history (but keep session alive)
  static Future<void> clearCurrentSession({ServiceType? serviceType}) async {
    if (_currentSessionId == null) return;

    try {
      final url = Uri.parse('$_mcpAgentUrl/session/clear');
      await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'session_id': _currentSessionId}),
          )
          .timeout(_healthTimeout);
      print('[ApiServiceManager] Session history cleared: $_currentSessionId');
    } catch (e) {
      print('[ApiServiceManager] Session clear error: $e');
    }
  }

  /// List sessions (if backend supports) - may be limited since sessions are temporary
  static Future<List<SessionInfo>> listSessions({
    required int userId,
    ServiceType? serviceType,
  }) async {
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

  /// ===== Health checks =====
  static Future<bool> checkMcpAgentHealth() async {
    // Cloud agents may not expose /health; try a few safe probes.
    try {
      final urlHealth = Uri.parse('$_mcpAgentUrl/health');
      final r1 = await http.get(urlHealth).timeout(_healthTimeout);
      if (r1.statusCode == 200) return true;
    } catch (_) {}

    try {
      final urlRoot = Uri.parse('$_mcpAgentUrl/');
      final r2 = await http.get(urlRoot).timeout(_healthTimeout);
      if (r2.statusCode >= 200 && r2.statusCode < 500) return true;
    } catch (_) {}

    try {
      final urlOptions = Uri.parse('$_mcpAgentUrl/chat');
      final r3 = await http.Request('OPTIONS', urlOptions)
          .send()
          .timeout(_healthTimeout);
      if (r3.statusCode >= 200 && r3.statusCode < 500) return true;
    } catch (_) {}

    if (_mcpAgentUrl.startsWith('https://')) {
      // soft-healthy to avoid blocking UI banners when cloud agent lacks /health
      return true;
    }
    return false;
  }

  static Future<ServiceHealthStatus> checkAllServicesHealth() async {
    final mcp = await checkMcpAgentHealth();
    return ServiceHealthStatus(
      mcpAgentAvailable: mcp,
      externalApiAvailable: false,
    );
  }

  // ===== QR PAYMENT =====
  static Future<QRPayResponse> payQr({
    required String receiverIban,
    required String receiverName,
    required double amount,
    String? note,
    ServiceType? serviceType,
    bool forceExternal = true, // kept for compatibility
  }) async {
    // External API is removed; MCP Agent does not support QR in this build.
    throw const ApiException('QR ödeme şu an desteklenmiyor.');
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
      metadata: (json['metadata'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
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
  final bool externalApiAvailable; // kept for backward-compat with UI

  const ServiceHealthStatus({
    required this.mcpAgentAvailable,
    required this.externalApiAvailable,
  });

  bool get anyServiceAvailable => mcpAgentAvailable || externalApiAvailable;
  bool get allServicesAvailable => mcpAgentAvailable && externalApiAvailable;

  ServiceType? get preferredAvailableService {
    if (mcpAgentAvailable) return ServiceType.mcpAgent;
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
  const ApiServiceException(this.message);
  @override
  String toString() => 'ApiServiceException: $message';
}
