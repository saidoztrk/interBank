import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Bu sınıf, uygulama genelinde kullanılacak Session ID'yi yönetir.
class SessionManager {
  static const String _sessionIdKey = 'session_id';
  static final _uuid = Uuid();
  static String? _sessionId;

  // Session ID'yi dışarıdan almak için kullanılan getter metodu.
  static String get sessionId {
    if (_sessionId == null) {
      throw Exception("Session ID is not initialized. Call initialize() first.");
    }
    return _sessionId!;
  }

  // Bu fonksiyon, uygulamanın başlangıcında bir kez çağrılmalıdır.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionIdKey);

    if (_sessionId == null) {
      _sessionId = _uuid.v4();
      await prefs.setString(_sessionIdKey, _sessionId!);
      print('Yeni Session ID oluşturuldu: $_sessionId');
    } else {
      print('Mevcut Session ID kullanılıyor: $_sessionId');
    }
  }
}