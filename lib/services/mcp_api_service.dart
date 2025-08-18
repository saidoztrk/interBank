// lib/services/mcp_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bot_badge_state.dart';

class McpApiService {
  // MCP Agent API URL - Android emülatör için 10.0.2.2 kullan
  static const String _baseUrl = 'http://10.0.2.2:8081';

  // Eğer gerçek cihazda test ediyorsanız, bilgisayarınızın IP'sini kullanın:
  // static const String _baseUrl = 'http://192.168.1.XXX:8081';

  static const Duration _timeout = Duration(seconds: 15);

  /// MCP Agent'a chat mesajı gönder ve yanıt al
  static Future<McpChatResponse> sendMessage({
    required String message,
    required int userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/chat');

      print('🚀 MCP Agent\'e istek gönderiliyor...');
      print('📍 URL: $url');
      print('👤 User ID: $userId');
      print('💬 Message: $message');

      final requestBody = {
        'user_id': userId,
        'message': message,
      };

      // UTF-8 encoding ile gönder
      final jsonBody = utf8.encode(jsonEncode(requestBody));

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonBody,
          )
          .timeout(_timeout);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return McpChatResponse.fromJson(data);
        } else {
          final errorMsg = data['error']?['message'] ?? 'Bilinmeyen hata';
          throw McpApiException(errorMsg, response.statusCode);
        }
      } else {
        throw McpApiException(
          'MCP Agent sunucu hatası: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      throw const McpApiException(
        'MCP Agent sunucusuna bağlanılamıyor. Network hatası.',
        0,
      );
    } on http.ClientException catch (e) {
      print('❌ HTTP Client Exception: $e');
      throw const McpApiException(
        'HTTP bağlantı hatası. MCP Agent (port 8081) çalışıyor mu?',
        0,
      );
    } on FormatException catch (e) {
      print('❌ Format Exception: $e');
      throw const McpApiException(
        'MCP Agent\'den geçersiz JSON yanıtı alındı.',
        0,
      );
    } catch (e) {
      print('❌ Genel hata: $e');
      if (e is McpApiException) rethrow;
      throw McpApiException(
        'Beklenmeyen hata: $e',
        0,
      );
    }
  }

  /// MCP Agent sağlık kontrolü - daha detaylı debug
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      print('🔍 MCP Agent sağlık kontrolü: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 5),
          );

      print('💊 Health Status: ${response.statusCode}');
      print('💊 Health Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health Check Hatası: $e');
      return false;
    }
  }

  /// MCP sunucularının durumunu kontrol et
  static Future<Map<String, bool>> checkMcpStatus() async {
    try {
      final url = Uri.parse('$_baseUrl/status');
      print('📊 MCP Status kontrolü: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 8),
          );

      print('📊 Status Response: ${response.statusCode}');
      print('📊 Status Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, bool>.from(data['mcp_servers'] ?? {});
      }
      return {};
    } catch (e) {
      print('❌ MCP Status Check Hatası: $e');
      return {};
    }
  }
}

/// MCP API yanıt modeli
class McpChatResponse {
  final bool success;
  final String message;
  final BotBadgeState badgeState;
  final String timestamp;
  final int userId;
  final Map<String, dynamic>? metadata;

  const McpChatResponse({
    required this.success,
    required this.message,
    required this.badgeState,
    required this.timestamp,
    required this.userId,
    this.metadata,
  });

  factory McpChatResponse.fromJson(Map<String, dynamic> json) {
    final responseText = json['response'] as String? ?? '';
    BotBadgeState badgeState = _determineBadgeFromContent(responseText);

    return McpChatResponse(
      success: json['success'] as bool? ?? false,
      message: responseText,
      badgeState: badgeState,
      timestamp: DateTime.now().toIso8601String(),
      userId: json['user_id'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static BotBadgeState _determineBadgeFromContent(String content) {
    final lowerContent = content.toLowerCase();

    if (lowerContent
        .contains(RegExp(r'(account|balance|money|transfer|payment|bank)'))) {
      return BotBadgeState.sekreter;
    }

    if (lowerContent
        .contains(RegExp(r'(connection|error|problem|unavailable)'))) {
      return BotBadgeState.noConnection;
    }

    if (lowerContent.contains(RegExp(r'(success|completed|done)'))) {
      return BotBadgeState.connection;
    }

    return BotBadgeState.sekreter;
  }
}

class McpApiException implements Exception {
  final String message;
  final int statusCode;

  const McpApiException(this.message, this.statusCode);

  @override
  String toString() => 'McpApiException: $message (Status: $statusCode)';
}
