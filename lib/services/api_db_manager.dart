// lib/services/api_db_manager.dart
// Erenay tarafından eklendi: Azure DB API istemcisi (login + müşteri)
// Log tag: [Erenay][DB]

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'session_manager.dart';

class ApiDbManager {
  ApiDbManager(this.baseUrl);
  final String baseUrl; // örn: https://interntech-db-api.azurewebsites.net

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        // ileride bearer token olursa buraya Authorization ekleriz
      };

  /// Login (backend token istemiyor; CustomerId & FullName dönüyor)
  /// username: "9001" | "11111111111" | "seda.sayan@example.com"
  /// password: "476982"
  Future<CustomerLoginResult> loginDb({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    // Log
    // ignore: avoid_print
    print('[Erenay][DB] POST $uri | username=$username, pin=******');

    final res = await http
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    // Log
    // ignore: avoid_print
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final dynamic body = jsonDecode(res.body);

      // Backend tek obje de döndürebilir, liste de; ikisini de ele al
      final Map<String, dynamic> obj = body is List && body.isNotEmpty
          ? (body.first as Map<String, dynamic>)
          : (body as Map<String, dynamic>);

      final int customerId = _asInt(obj['CustomerId'] ?? obj['customerId']);
      final String fullName = (obj['FullName'] ?? obj['fullName'] ?? '').toString();

      // --- Session kayıtları ---
      // Uygulama genelinde görünen isim olsun:
      await SessionManager.saveUsername(fullName.isNotEmpty ? fullName : username);
      // Home/DB çağrıları için numeric ID:
      await SessionManager.saveCustomerNo(customerId);

      // PIN akışı için "son kullanıcı" bilgilerini ayrı saklayalım
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
    final uri = Uri.parse('$baseUrl/api/customers/$customerNoOrId');
    // ignore: avoid_print
    print('[Erenay][DB] GET $uri');

    final res = await http.get(uri).timeout(const Duration(seconds: 15));

    // ignore: avoid_print
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return Customer.fromJson(j);
    }
    throw Exception('Customer alınamadı: ${res.statusCode} ${res.body}');
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
