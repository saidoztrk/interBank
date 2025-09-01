// lib/services/api_db_manager.dart
// Erenay tarafından eklendi: Azure DB API istemcisi (login + müşteri + hesaplar)
// Log tag: [Erenay][DB]

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/customer.dart';
import '../models/account.dart';
import 'session_manager.dart';

class ApiDbManager {
  ApiDbManager(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl; // örn: https://interntech-db-api.azurewebsites.net
  final http.Client _client;

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        // ileride bearer token olursa buraya Authorization ekleriz
      };

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// Login (backend token istemiyor; CustomerId & FullName dönüyor)
  /// username: "9001" | "11111111111" | "seda.sayan@example.com"
  /// password: "476982"
  Future<CustomerLoginResult> loginDb({
    required String username,
    required String password,
  }) async {
    final uri = _u('/api/auth/login');
    // ignore: avoid_print
    print('[Erenay][DB] POST $uri | username=$username, pin=******');

    final res = await _client
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    // ignore: avoid_print
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final dynamic body = jsonDecode(res.body);

      // Backend tek obje de döndürebilir, liste de; ikisini de ele al
      final Map<String, dynamic> obj = body is List && body.isNotEmpty
          ? (body.first as Map<String, dynamic>)
          : (body as Map<String, dynamic>);

      final int customerId = _asInt(obj['CustomerId'] ?? obj['customerId']);
      final String fullName =
          (obj['FullName'] ?? obj['fullName'] ?? '').toString();

      // --- Session kayıtları ---
      await SessionManager.saveUsername(
          fullName.isNotEmpty ? fullName : username);
      await SessionManager.saveCustomerNo(customerId);

      // PIN akışı için "son kullanıcı" bilgileri
      await SessionManager.saveLastUsername(username);
      if (fullName.isNotEmpty) {
        await SessionManager.saveLastFullName(fullName);
      }

      return CustomerLoginResult(customerId: customerId, fullName: fullName);
    }

    throw Exception('DB API login başarısız: ${res.statusCode} ${res.body}');
  }

  /// Müşteri detayı
  Future<Customer> getCustomer(String customerNoOrId) async {
    final uri = _u('/api/customers/$customerNoOrId');
    // ignore: avoid_print
    print('[Erenay][DB] GET $uri');

    final res =
        await _client.get(uri, headers: _jsonHeaders()).timeout(const Duration(seconds: 15));

    // ignore: avoid_print
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return Customer.fromJson(j);
    }
    throw Exception('Customer alınamadı: ${res.statusCode} ${res.body}');
  }

  /// Hesap listesi: GET /api/accounts/by-customer/{customer_id}
  /// Home ekranındaki bakiye için burayı kullanıyoruz.
  Future<List<Account>> getAccountsByCustomer(String customerId) async {
    final uri = _u('/api/accounts/by-customer/$customerId');
    // ignore: avoid_print
    print('[Erenay][DB] GET $uri');

    final res =
        await _client.get(uri, headers: _jsonHeaders()).timeout(const Duration(seconds: 15));

    // ignore: avoid_print
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is! List) {
        throw Exception('Accounts response is not a list: $decoded');
      }

      // ✅ Tüm alanları (Iban, AccountNo, Status, is_blocked, vb.) Account.fromJson ile al
      final accounts = decoded
          .map<Account>((e) => Account.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // ignore: avoid_print
      print('[Erenay][DB] [Accounts] n=${accounts.length}');
      return accounts;
    }

    throw Exception('Accounts alınamadı: ${res.statusCode} ${res.body}');
  }
}

// ----------------- yardımcılar -----------------

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final fixed = v.replaceAll(',', '.'); // "12,5" -> "12.5"
    return double.tryParse(fixed) ?? 0.0;
  }
  return 0.0;
}

class CustomerLoginResult {
  final int customerId;
  final String fullName;
  CustomerLoginResult({required this.customerId, required this.fullName});
}
