// lib/providers/db_provider.dart
// Erenay tarafından eklendi: DB API'ye erişim için basit ChangeNotifier
// login_screen içinde context.read<DbProvider>().api ile ApiDbManager'a erişiyoruz.

import 'package:flutter/foundation.dart';
import '../services/api_db_manager.dart';
import '../models/customer.dart';
import '../models/account.dart';

class DbProvider with ChangeNotifier {
  DbProvider(this.api);
  final ApiDbManager api;

  // Müşteri state
  Customer? customer;

  // ✅ Account state
  List<Account> accounts = [];

  bool loading = false;
  String? error;

  // Opsiyonel müşteri fetch (Home için vs.)
  Future<void> loadCustomerById(int customerId) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final c = await api.getCustomer(customerId.toString());
      customer = c;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ✅ Yeni: accounts fetch
  Future<void> loadAccountsByCustomer(int customerId) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final list = await api.getAccountsByCustomer(customerId.toString());
      accounts = list;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    customer = null;
    accounts = [];
    loading = false;
    error = null;
    notifyListeners();
  }
}
