// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bot_badge_state.dart';

// PUBSPEC.YAML'a ekleyin:
// dependencies:
//   http: ^1.1.0

class ApiService {
  // Backend URL - PORT 3001 kullanıyoruz
  static const String _baseUrl = 'http://10.0.2.2:3001'; // Android emülatör
  // static const String _baseUrl = 'http://192.168.1.XXX:3001'; // Gerçek cihaz için IP'nizi yazın
  // static const String _baseUrl = 'http://localhost:3001'; // iOS simülatör

  static const Duration _timeout = Duration(seconds: 10);

  /// Backend'e chat mesajı gönder ve yanıt al
  static Future<ChatResponse> sendMessage({
    required String message,
    String userId = 'team1',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/chat');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'userId': userId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const ApiException(
        'Ağ bağlantısı yok. İnternet bağlantınızı kontrol edin.',
        0,
      );
    } on http.ClientException {
      throw const ApiException(
        'Sunucuya bağlanılamıyor. Lütfen daha sonra tekrar deneyin.',
        0,
      );
    } on FormatException {
      throw const ApiException(
        'Sunucudan geçersiz yanıt alındı.',
        0,
      );
    } catch (e) {
      throw ApiException(
        'Beklenmeyen bir hata oluştu: $e',
        0,
      );
    }
  }

  /// Backend sağlık kontrolü
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// API yanıt modeli
class ChatResponse {
  final bool success;
  final String message;
  final BotBadgeState badgeState;
  final String timestamp;
  final String userId;

  const ChatResponse({
    required this.success,
    required this.message,
    required this.badgeState,
    required this.timestamp,
    required this.userId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen badge string'ini enum'a çevir
    final badgeString = json['badge'] as String? ?? 'sekreter';
    final badgeState = _parseBadgeState(badgeString);

    return ChatResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      badgeState: badgeState,
      timestamp: json['timestamp'] as String? ?? '',
      userId: json['userId'] as String? ?? 'team1',
    );
  }

  static BotBadgeState _parseBadgeState(String badge) {
    switch (badge.toLowerCase()) {
      case 'thinking':
        return BotBadgeState.thinking;
      case 'writing':
        return BotBadgeState.writing;
      case 'connection':
        return BotBadgeState.connection;
      case 'noconnection':
      case 'no_connection':
        return BotBadgeState.noConnection;
      case 'sekreter':
      case 'normal':
      default:
        return BotBadgeState.sekreter;
    }
  }
}

/// API hata sınıfı
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
