// lib/services/mcp_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bot_badge_state.dart';

class McpApiService {
  // MCP Agent API URL - PORT 8081
  static const String _baseUrl = 'http://10.0.2.2:8081'; // Android emülatör
  // static const String _baseUrl = 'http://192.168.1.XXX:8081'; // Gerçek cihaz için IP'nizi yazın
  // static const String _baseUrl = 'http://localhost:8081'; // iOS simülatör

  static const Duration _timeout =
      Duration(seconds: 15); // MCP için daha uzun timeout

  /// MCP Agent'a chat mesajı gönder ve yanıt al
  static Future<McpChatResponse> sendMessage({
    required String message,
    required int userId, // MCP Agent int user_id bekliyor
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

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // MCP Agent yanıt formatını kontrol et
        if (data['success'] == true) {
          return McpChatResponse.fromJson(data);
        } else {
          // Hatalı yanıt
          final errorMsg = data['error']?['message'] ?? 'Bilinmeyen hata';
          throw McpApiException(errorMsg, response.statusCode);
        }
      } else {
        throw McpApiException(
          'MCP Agent sunucu hatası: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const McpApiException(
        'MCP Agent sunucusuna bağlanılamıyor. Sunucunun çalıştığını kontrol edin.',
        0,
      );
    } on http.ClientException {
      throw const McpApiException(
        'HTTP bağlantı hatası. MCP Agent (port 8081) çalışıyor mu?',
        0,
      );
    } on FormatException {
      throw const McpApiException(
        'MCP Agent\'den geçersiz JSON yanıtı alındı.',
        0,
      );
    } catch (e) {
      if (e is McpApiException) rethrow;
      throw McpApiException(
        'Beklenmeyen hata: $e',
        0,
      );
    }
  }

  /// MCP Agent sağlık kontrolü
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      print('🔍 MCP Agent sağlık kontrolü: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 5),
          );

      print('💊 Health Status: ${response.statusCode}');
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
      final response = await http.get(url).timeout(
            const Duration(seconds: 8),
          );

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
  final Map<String, dynamic>? metadata; // MCP'den gelen ek bilgiler

  const McpChatResponse({
    required this.success,
    required this.message,
    required this.badgeState,
    required this.timestamp,
    required this.userId,
    this.metadata,
  });

  factory McpChatResponse.fromJson(Map<String, dynamic> json) {
    // MCP Agent yanıt formatına uygun parsing
    final responseText = json['response'] as String? ?? '';

    // Badge state'i response içeriğine göre belirle
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

  /// Response içeriğine göre badge state belirle
  static BotBadgeState _determineBadgeFromContent(String content) {
    final lowerContent = content.toLowerCase();

    // Banking/finance kelimeleri için özel badge
    if (lowerContent
        .contains(RegExp(r'(hesap|bakiye|para|transfer|ödeme|fatura|banka)'))) {
      return BotBadgeState.sekreter;
    }

    // Bağlantı sorunları
    if (lowerContent.contains(RegExp(r'(bağlant|hata|sorun|mevcut değil)'))) {
      return BotBadgeState.noConnection;
    }

    // Başarılı işlemler
    if (lowerContent.contains(RegExp(r'(başarı|tamamland|gerçekleştir)'))) {
      return BotBadgeState.connection;
    }

    // Varsayılan banking assistant
    return BotBadgeState.sekreter;
  }
}

/// MCP API hata sınıfı
class McpApiException implements Exception {
  final String message;
  final int statusCode;

  const McpApiException(this.message, this.statusCode);

  @override
  String toString() => 'McpApiException: $message (Status: $statusCode)';
}
