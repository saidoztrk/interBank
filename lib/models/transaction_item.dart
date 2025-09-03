// lib/models/transaction_item.dart
/// Uygulama içi ortak işlem modeli
/// Kaynak:
/// - /api/transactions/by-account/{account_id}   (hesap/debit)
/// - /api/credit-card-transactions/...          (kredi kartı)
///
/// Not: Alan adları Swagger'da snake_case; ama tolerant parser var.
class TransactionItem {
  /// Uygulama içi benzersiz kimlik (stringleştirilmiş)
  final String id;

  /// "account" | "credit"
  final String source;

  /// Kaynağa bağlı opsiyonel alanlar:
  final String? accountId;
  final String? cardId;

  /// Pozitif = gelir, negatif = gider
  final double amount;

  /// TRY, USD, EUR vb.
  final String currency;

  /// Özet / açıklama / merchant
  final String? description;

  /// Bankanın type alanı (TRANSFER_IN, POS, …) — varsa
  final String? type;

  /// Bankanın status alanı (Posted/Pending/… ) — varsa
  final String? status;

  /// ISO format tarih (ekranda parse edip gösteriyoruz)
  final String txnDate;

  TransactionItem({
    required this.id,
    required this.source,
    required this.amount,
    required this.currency,
    required this.txnDate,
    this.accountId,
    this.cardId,
    this.description,
    this.type,
    this.status,
  });

  // ----------------- Yardımcılar -----------------
  static T? _pick<T>(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k] as T;
    }
    return null;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final fixed = v.toString().replaceAll(',', '.');
    return double.tryParse(fixed) ?? 0.0;
  }

  static String _asString(dynamic v) => (v ?? '').toString();

  // ----------------- Factory: Hesap işlemi -----------------
  /// /api/transactions/by-account/{account_id}
  /// Örnek alanlar:
  /// {
  ///   "transactionId": 95000000044,
  ///   "accountId": "91001",
  ///   "amount": -280.0,
  ///   "type": "TRANSFER_IN",
  ///   "description": "Transfer from Ayse Kaya",
  ///   "currency": "TRY",
  ///   "transactionDate": "2025-08-25T21:47:..",
  ///   "status": "Posted"
  /// }
  factory TransactionItem.fromAccountJson(Map<String, dynamic> j) {
    final id = _pick<dynamic>(j, ['transactionId', 'TransactionId', 'id'])?.toString() ?? '';
    final accountId = _pick<dynamic>(j, ['accountId', 'AccountId'])?.toString();
    final amount = _asDouble(_pick<dynamic>(j, ['amount', 'Amount']));
    final currency = _asString(_pick<dynamic>(j, ['currency', 'Currency']));
    final txnDate = _asString(_pick<dynamic>(j, ['transactionDate', 'TransactionDate', 'txn_date', 'date']));
    final type = _pick<String>(j, ['type', 'Type']);
    final status = _pick<String>(j, ['status', 'Status']);
    final desc = _pick<String>(j, ['description', 'Description']);

    return TransactionItem(
      id: id,
      source: 'account',
      accountId: accountId,
      amount: amount,
      currency: currency.isEmpty ? 'TRY' : currency,
      txnDate: txnDate,
      type: type,
      status: status,
      description: desc,
    );
  }

  // ----------------- Factory: Kredi kartı işlemi -----------------
  /// /api/credit-card-transactions/by-card/{card_id}
  /// veya /by-customer/{customer_id}
  /// Örnek alanlar:
  /// {
  ///   "credit_card_trn_id": 5,
  ///   "card_id": 3006,
  ///   "amount": -86.42,
  ///   "currency_code": "TL",
  ///   "txn_date": "2025-08-21T15:00:00",
  ///   "description": "Market Harcaması"
  /// }
  factory TransactionItem.fromCreditJson(Map<String, dynamic> j) {
    final id = _pick<dynamic>(j, ['credit_card_trn_id', 'card_trn_id', 'id'])?.toString() ?? '';
    final cardId = _pick<dynamic>(j, ['card_id', 'cardId'])?.toString();
    final amount = _asDouble(_pick<dynamic>(j, ['amount', 'Amount']));
    final currency = _asString(_pick<dynamic>(j, ['currency_code', 'currency', 'Currency']));
    final txnDate = _asString(_pick<dynamic>(j, ['txn_date', 'transactionDate', 'TransactionDate', 'date']));
    final desc = _pick<String>(j, ['description', 'merchant', 'title']);
    // Kredi kartı API'larında type/status genelde yok; null bırakılır.
    return TransactionItem(
      id: id,
      source: 'credit',
      cardId: cardId,
      amount: amount,
      currency: currency.isEmpty ? 'TRY' : currency,
      txnDate: txnDate,
      description: desc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'accountId': accountId,
        'cardId': cardId,
        'amount': amount,
        'currency': currency,
        'description': description,
        'type': type,
        'status': status,
        'txnDate': txnDate,
      };

  // UI yardımcıları - BUNLARI EKLEYİN:
  bool get isIncome => amount >= 0;
  String get sign => isIncome ? '+' : '-';
  
  // Yeni screen için ek property'ler:
  DateTime? get date {
    try {
      return DateTime.tryParse(txnDate);
    } catch (e) {
      return null;
    }
  }
  
  String? get merchantName => description;
  String? get category => type;
}