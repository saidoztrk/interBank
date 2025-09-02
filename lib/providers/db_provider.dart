// lib/providers/db_provider.dart
// DB API + state (müşteri, hesaplar, kartlar, seçim, son işlemler)

import 'package:flutter/foundation.dart';

import '../services/api_db_manager.dart';
import '../models/customer.dart';
import '../models/account.dart';
import '../models/debit_card.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';

class DbProvider with ChangeNotifier {
  DbProvider(this.api);

  final ApiDbManager api;

  // ---- Customer / Accounts ----
  Customer? _customer;
  List<Account> _accounts = <Account>[];

  Customer? get customer => _customer;
  List<Account> get accounts => List.unmodifiable(_accounts);

  // ---- Cards ----
  final List<DebitCard> _debitCards = <DebitCard>[];
  final List<CreditCard> _creditCards = <CreditCard>[];

  List<DebitCard> get debitCards => List.unmodifiable(_debitCards);
  List<CreditCard> get creditCards => List.unmodifiable(_creditCards);

  // ---- Selection (HomeScreen'in beklediği) ----
  // 'debit' | 'credit' | null
  String? _selectedCardSource;
  DebitCard? _selectedDebit;
  CreditCard? _selectedCredit;

  String? get selectedCardSource => _selectedCardSource;
  DebitCard? get selectedDebit => _selectedDebit;
  CreditCard? get selectedCredit => _selectedCredit;

  // ---- Recent Transactions (seçime bağlı) ----
  final List<TransactionItem> _recentTransactions = <TransactionItem>[];
  List<TransactionItem> get recentTransactions => List.unmodifiable(_recentTransactions);

  bool loading = false;
  String? error;

  // ---- Müşteri + Hesaplar (birlikte) ----
  Future<void> loadCustomerById(int customerId) async {
    try {
      loading = true; error = null; notifyListeners();

      final c = await api.getCustomer(customerId);               // <-- INT
      final accs = await api.getAccountsByCustomer(customerId);  // <-- INT

      _customer = c;
      _accounts = accs;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  // ---- Sadece Hesaplar ----
  Future<void> loadAccountsByCustomer(int customerId) async {
    try {
      loading = true; error = null; notifyListeners();

      final accs = await api.getAccountsByCustomer(customerId);  // <-- INT
      _accounts = accs;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  // ---- Kartlar (debit + credit) ----
  Future<void> loadCardsByCustomer(int customerId) async {
    try {
      loading = true; error = null; notifyListeners();

      final debits = await api.getDebitCardsByCustomer(customerId);
      final credits = await api.getCreditCardsByCustomer(customerId);

      _debitCards
        ..clear()
        ..addAll(debits);
      _creditCards
        ..clear()
        ..addAll(credits);

      // kartlar yenilendi → seçim ve işlemleri sıfırla
      _selectedCardSource = null;
      _selectedDebit = null;
      _selectedCredit = null;
      _recentTransactions.clear();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  // ---- Seçim yardımcıları ----
  void selectDebit(DebitCard? card) {
    _selectedCardSource = card == null ? null : 'debit';
    _selectedDebit = card;
    _selectedCredit = null;
    notifyListeners();
  }

  void selectCredit(CreditCard? card) {
    _selectedCardSource = card == null ? null : 'credit';
    _selectedCredit = card;
    _selectedDebit = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCardSource = null;
    _selectedDebit = null;
    _selectedCredit = null;
    _recentTransactions.clear();
    notifyListeners();
  }

  // ---- Seçime göre son işlemler ----
  Future<void> loadRecentTransactionsForSelection({int limit = 20}) async {
    try {
      loading = true; error = null; notifyListeners();

      _recentTransactions.clear();

      if (_selectedCardSource == 'debit' && _selectedDebit != null) {
        final accId = _selectedDebit!.accountId; // String
        if (accId.isNotEmpty) {
          final tx = await api.getTransactionsByAccount(accId, limit: limit);
          _recentTransactions.addAll(tx);
        }
      } else if (_selectedCardSource == 'credit' && _selectedCredit != null) {
        final accId = _selectedCredit!.accountId; // String?
        if (accId != null && accId.isNotEmpty) {
          final tx = await api.getTransactionsByAccount(accId, limit: limit);
          _recentTransactions.addAll(tx);
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  // ---- Temizle ----
  void clear() {
    _customer = null;
    _accounts = [];
    _debitCards.clear();
    _creditCards.clear();
    _selectedCardSource = null;
    _selectedDebit = null;
    _selectedCredit = null;
    _recentTransactions.clear();
    loading = false;
    error = null;
    notifyListeners();
  }
}
