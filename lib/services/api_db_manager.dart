// lib/services/api_db_manager.dart
// Azure DB API istemcisi (login + müşteri + hesaplar + kartlar + işlemler)
// Log tag: [Erenay][DB]

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/customer.dart';
import '../models/account.dart';
import '../models/debit_card.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import 'session_manager.dart';

class ApiDbManager {
  ApiDbManager(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl; // örn: https://interntech-db-api.azurewebsites.net
  final http.Client _client;

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
      };

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    if (q == null || q.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...q.map((k, v) => MapEntry(k, v?.toString())),
    });
  }

  // ---------- Helpers ----------
  List<dynamic> _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['value'] is List) return body['value'] as List;
    return const [];
  }

  T _decode<T>(http.Response res) {
    final text = res.body;
    try {
      return json.decode(text) as T;
    } catch (_) {
      if (T == Map<String, dynamic>) return <String, dynamic>{} as T;
      if (T == List<dynamic>) return <dynamic>[] as T;
      rethrow;
    }
  }

  // ---------- Auth ----------
  Future<CustomerLoginResult> loginDb({
    required String username,
    required String password,
  }) async {
    final uri = _u('/api/auth/login');
    print('[Erenay][DB] POST $uri | username=$username, pin=******');

    final res = await _client.post(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final m = _decode<Map<String, dynamic>>(res);
      final cid = m['CustomerId'] ?? m['customerId'] ?? m['id'];
      final name = m['FullName'] ?? m['fullName'] ?? m['name'] ?? '';
      final parsedId = (cid is String) ? int.tryParse(cid) ?? 0 : (cid ?? 0) as int;

      await SessionManager.saveCustomerNo(parsedId);
      await SessionManager.saveLastFullName(name.toString());

      return CustomerLoginResult(customerId: parsedId, fullName: name.toString());
    }
    throw Exception('Login failed (${res.statusCode}): ${res.body}');
  }

  // ---------- Customer ----------
  Future<Customer> getCustomer(int customerId) async {
    final uri = _u('/api/customers/$customerId');
    print('[Erenay][DB] GET $uri');

    final res = await _client.get(uri, headers: _jsonHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final m = _decode<Map<String, dynamic>>(res);
      return Customer.fromJson(m);
    }
    throw Exception('getCustomer failed (${res.statusCode}): ${res.body}');
  }

  // ---------- Accounts ----------
  Future<List<Account>> getAccountsByCustomer(int customerId) async {
    final uri = _u('/api/accounts/by-customer/$customerId');
    print('[Erenay][DB] GET $uri');

    final res = await _client.get(uri, headers: _jsonHeaders());
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final any = _decode<dynamic>(res);
      final list = _asList(any);
      return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('getAccountsByCustomer failed (${res.statusCode}): ${res.body}');
  }

  // ---------- Debit Cards ----------
  Future<List<DebitCard>> getDebitCardsByCustomer(int customerId) async {
    final uri = _u('/api/debit-cards/by-customer/$customerId');
    print('[Erenay][DB] GET $uri');

    final res = await _client.get(uri, headers: _jsonHeaders());
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final any = _decode<dynamic>(res);
      final list = _asList(any);
      return list.map((e) => DebitCard.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('getDebitCardsByCustomer failed (${res.statusCode}): ${res.body}');
  }

  // ---------- Credit Cards ----------
  Future<List<CreditCard>> getCreditCardsByCustomer(int customerId) async {
    final uri = _u('/api/credit-cards/by-customer/$customerId');
    print('[Erenay][DB] GET $uri');

    final res = await _client.get(uri, headers: _jsonHeaders());
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final any = _decode<dynamic>(res);
      final list = _asList(any);
      return list.map((e) => CreditCard.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('getCreditCardsByCustomer failed (${res.statusCode}): ${res.body}');
  }

  // ---------- Transactions (by account) ----------
  /// /api/transactions/by-account/{accountId}?limit=20
  Future<List<TransactionItem>> getTransactionsByAccount(
    String accountId, {
    int limit = 20,
  }) async {
    final uri = _u('/api/transactions/by-account/$accountId', {'limit': limit});
    print('[Erenay][DB] GET $uri');

    final res = await _client.get(uri, headers: _jsonHeaders());
    print('[Erenay][DB] <= ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final any = _decode<dynamic>(res);
      final list = _asList(any);
      return list
          .map((e) => TransactionItem.fromAccountJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getTransactionsByAccount failed (${res.statusCode}): ${res.body}');
  }
}

// Basit login sonucu DTO
class CustomerLoginResult {
  final int customerId;
  final String fullName;
  CustomerLoginResult({required this.customerId, required this.fullName});
}
