import 'package:flutter/foundation.dart';

import '../services/api_db_manager.dart';
import '../models/customer.dart';
import '../models/account.dart';
import '../models/debit_card.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../models/transfer_history_item.dart';
// lib/providers/db_provider.dart
// DB API + state (müşteri, hesaplar, kartlar, seçim, son işlemler + transfer geçmişi)

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

  // ---- Transfer Geçmişi (account-based) ----
  final List<TransferHistoryItem> _transfers = <TransferHistoryItem>[];
  List<TransferHistoryItem> get transfers => List.unmodifiable(_transfers);

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
      if (kDebugMode) {
        print('[Erenay][DBP] loaded ${_accounts.length} accounts');
      }
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

  // ---- Transfer Geçmişi: Hesap numarasına göre (login olan hesabın accountNo'su) ----
  Future<void> loadTransfersByAccount(String accountId, {int? limit}) async {
    try {
      loading = true; error = null; notifyListeners();

      if (kDebugMode) {
        print('[Erenay][HOME][FEED] call transfers | acc=$accountId');
      }

      _transfers
        ..clear()
        ..addAll(await api.getTransfersByAccount(accountId, limit: limit));

      if (_transfers.isNotEmpty) {
        _transfers.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final newest = _transfers.first.occurredAt.toIso8601String();
        final oldest = _transfers.last.occurredAt.toIso8601String();
        if (kDebugMode) {
          print('[Erenay][HOME][FEED] result | count=${_transfers.length} '
              '| newest=$newest | oldest=$oldest');
        }
      } else {
        if (kDebugMode) {
          print('[Erenay][HOME][FEED] result | count=0');
        }
      }
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('[Erenay][ERR][HOME] transfers failed | acc=$accountId | msg=$e');
      }
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
    _transfers.clear();
    loading = false;
    error = null;
    notifyListeners();
  }
}
