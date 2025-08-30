// lib/services/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionManager {
  static SharedPreferences? _prefs;

  // Mevcut anahtarlar (korunuyor)
  static const String _kSessionId  = 'session_id';
  static const String _kCustomerNo = 'customer_no';
  static const String _kUsername   = 'username';

  // ------------------------------------------------------------
  // Erenay tarafından eklendi: DB API token anahtarı
  // Sadece DB ile konuşuyorsak bu yeterli.
  static const String _kDbToken    = 'db_auth_token';
  // ------------------------------------------------------------

  /// Uygulama açılışında 1 kez çağırın.
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // SessionId yoksa üret
    final existing = _prefs?.getString(_kSessionId);
    if (existing == null || existing.isEmpty) {
      final newId = const Uuid().v4();
      await _prefs?.setString(_kSessionId, newId);
    }
  }

  // ------------------------------------------------------------
  // Erenay tarafından eklendi: Lazy-init güvenliği
  // initialize() atlanmışsa bile güvende ol.
  static Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  // ------------------------------------------------------------

  /// Benzersiz oturum kimliği (UUID). initialize() sonrası hazırdır.
  static String get sessionId {
    final id = _prefs?.getString(_kSessionId);
    if (id == null || id.isEmpty) {
      throw Exception("Session ID is not initialized. Call initialize() first.");
    }
    return id;
  }

  /// Kullanıcı adı saklama/silme
  static Future<void> saveUsername(String? username) async {
    final prefs = await _ensurePrefs();
    if (username == null) {
      await prefs.remove(_kUsername);
    } else {
      await prefs.setString(_kUsername, username);
    }
  }

  static String? get username => _prefs?.getString(_kUsername);

  /// Customer no saklama/silme
  static Future<void> saveCustomerNo(int? customerNo) async {
    final prefs = await _ensurePrefs();
    if (customerNo == null) {
      await prefs.remove(_kCustomerNo);
    } else {
      await prefs.setInt(_kCustomerNo, customerNo);
    }
  }

  static int? get customerNo {
    if (!(_prefs?.containsKey(_kCustomerNo) ?? false)) return null;
    return _prefs?.getInt(_kCustomerNo);
  }

  // ------------------------------------------------------------
  // Erenay tarafından eklendi: DB API token yönetimi
  // DB login/refresh sonrası buraya yazılır/okunur.
  static Future<void> saveDbToken(String? token) async {
    final prefs = await _ensurePrefs();
    if (token == null || token.isEmpty) {
      await prefs.remove(_kDbToken);
    } else {
      await prefs.setString(_kDbToken, token);
    }
  }

  static String? get dbToken => _prefs?.getString(_kDbToken);
  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // Erenay tarafından eklendi: (Opsiyonel) Esnek key/value yardımcıları
  // Küçük konfigler için işine yarayabilir. İstemezsen silebilirsin.
  static Future<void> saveValue(String key, String? value) async {
    final prefs = await _ensurePrefs();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  static Future<String?> getValue(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.getString(key);
  }

  static Future<void> removeKey(String key) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(key);
  }

  static bool hasKey(String key) => _prefs?.containsKey(key) ?? false;
  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // Erenay tarafından eklendi: Temizleme yardımcıları
  // Tümü: Tüm verileri siler (session_id DAHİL) -> Tam reset
  static Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    await prefs.clear();
  }

  // session_id KORUNUR, diğer her şey silinir -> app-level logout gibi
  static Future<void> clearExceptSessionId() async {
    final prefs = await _ensurePrefs();
    final sid = prefs.getString(_kSessionId);
    await prefs.clear();
    if (sid != null && sid.isNotEmpty) {
      await prefs.setString(_kSessionId, sid);
    }
  }

  // Yalnızca auth ile ilgili alanları temizle (logout önerisi)
  static Future<void> clearAuthOnly() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_kUsername);
    await prefs.remove(_kCustomerNo);
    await prefs.remove(_kDbToken);
  }


  // ------------------------------------------------------------


  // Erenay tarafından eklendi: Son kullanılan kullanıcı bilgileri
static Future<void> saveLastUsername(String v) async => saveValue('last_username', v);
static Future<String?> getLastUsername() async => getValue('last_username');

static Future<void> saveLastFullName(String v) async => saveValue('last_full_name', v);
static Future<String?> getLastFullName() async => getValue('last_full_name');

}
