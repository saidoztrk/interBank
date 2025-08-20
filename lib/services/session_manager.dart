import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionManager {
  static SharedPreferences? _prefs;

  static const String _kSessionId = 'session_id';
  static const String _kCustomerNo = 'customer_no';
  static const String _kUsername = 'username';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final existing = _prefs?.getString(_kSessionId);
    if (existing == null || existing.isEmpty) {
      final newId = const Uuid().v4();
      await _prefs?.setString(_kSessionId, newId);
    }
  }

  static String get sessionId {
    final id = _prefs?.getString(_kSessionId);
    if (id == null || id.isEmpty) {
      throw Exception(
          "Session ID is not initialized. Call initialize() first.");
    }
    return id;
  }

  static Future<void> saveUsername(String? username) async {
    if (username == null) {
      await _prefs?.remove(_kUsername);
    } else {
      await _prefs?.setString(_kUsername, username);
    }
  }

  static String? get username => _prefs?.getString(_kUsername);

  static Future<void> saveCustomerNo(int? customerNo) async {
    if (customerNo == null) {
      await _prefs?.remove(_kCustomerNo);
    } else {
      await _prefs?.setInt(_kCustomerNo, customerNo);
    }
  }

  static int? get customerNo {
    if (!(_prefs?.containsKey(_kCustomerNo) ?? false)) return null;
    return _prefs?.getInt(_kCustomerNo);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
