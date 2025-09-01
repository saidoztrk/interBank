// lib/models/account.dart
class Account {
  // --- Zorunlu alanlar (mevcut kullanımı bozmaz) ---
  final String accountId;
  final String type;
  final String currency;
  final double balance;

  // --- Yeni alanlar (opsiyonel) ---
  /// Swagger’da "Iban"
  final String? iban;

  /// Swagger’da "AccountNo"
  final String? accountNo;

  /// Swagger’da "Status"
  final String? status;

  /// Swagger’da "is_blocked" (0/1). Backend bool dönerse de tolere edilir.
  final int? isBlocked;

  Account({
    required this.accountId,
    required this.type,
    required this.currency,
    required this.balance,
    this.iban,
    this.accountNo,
    this.status,
    this.isBlocked,
  });

  factory Account.fromJson(Map<String, dynamic> j) {
    // Yardımcı: sayıyı güvenle double'a çevir
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    // Yardımcı: çoklu anahtar desteği (Swagger/PascalCase & camelCase)
    T? _pick<T>(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k] as T;
      }
      return null;
    }

    final accId = _pick<dynamic>(['accountId', 'AccountId']);
    final type   = _pick<String>(['type', 'Type']) ?? '';
    final curr   = _pick<String>(['currency', 'Currency']) ?? 'TRY';
    final bal    = _toDouble(_pick<dynamic>(['balance', 'Balance']));

    return Account(
      accountId: accId?.toString() ?? '',
      type: type,
      currency: curr,
      balance: bal,
      iban: _pick<String>(['iban', 'Iban']),
      accountNo: _pick<dynamic>(['accountNo', 'AccountNo'])?.toString(),
      status: _pick<String>(['status', 'Status']),
      isBlocked: (() {
        final v = _pick<dynamic>(['is_blocked', 'isBlocked']);
        if (v == null) return null;
        if (v is bool) return v ? 1 : 0;
        return int.tryParse(v.toString());
      })(),
    );
  }

  Map<String, dynamic> toJson() => {
        // Her iki şekli de koruyoruz; gerekirse tekine indirgenebilir
        'AccountId': accountId,
        'Type': type,
        'Currency': currency,
        'Balance': balance,
        'Iban': iban,
        'AccountNo': accountNo,
        'Status': status,
        'is_blocked': isBlocked,
      };
}
