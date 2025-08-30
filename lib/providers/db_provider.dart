// lib/providers/db_provider.dart
// Erenay tarafından eklendi: DB API'ye erişim için basit ChangeNotifier
// login_screen içinde context.read<DbProvider>().api ile ApiDbManager'a erişiyoruz.

import 'package:flutter/foundation.dart';
import '../services/api_db_manager.dart';
import '../models/customer.dart';

class DbProvider with ChangeNotifier {
  DbProvider(this.api);
  final ApiDbManager api;

  // İstersen ek state saklayabilirsin:
  Customer? customer;
  bool loading = false;
  String? error;

  // Erenay: opsiyonel müşteri fetch (Home için vs.)
  Future<void> loadCustomerById(int customerId) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      // API hem müşteriNo hem id ile kabul ediyor (biz string gönderiyoruz)
      final c = await api.getCustomer(customerId.toString());
      customer = c;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    customer = null;
    loading = false;
    error = null;
    notifyListeners();
  }
}
