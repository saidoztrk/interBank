// lib/models/debit_card.dart
class DebitCard {
  final String cardId;                 // "4001"
  final String customerId;             // "9001"
  final String accountId;              // "91001"
  final String cardNumber;             // "5521000000000001"
  final String? cardBrand;             // "VISA" | "MASTERCARD" | ...
  final String? cardType;              // "debit" vs.
  final bool? isActive;                // 1/0 veya true/false gelebilir
  final bool? isBlocked;               // 1/0 veya true/false gelebilir
  final String? blockReason;           // nullable
  final int? dailyTransactionLimit;    // 500000 gibi
  final String? validThrough;          // "2028-12-31" (yyyy-MM-dd)

  DebitCard({
    required this.cardId,
    required this.customerId,
    required this.accountId,
    required this.cardNumber,
    this.cardBrand,
    this.cardType,
    this.isActive,
    this.isBlocked,
    this.blockReason,
    this.dailyTransactionLimit,
    this.validThrough,
  });

  /// Swagger/PascalCase & camelCase anahtar toleransı
  factory DebitCard.fromJson(Map<String, dynamic> j) {
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k] as T;
      }
      return null;
    }

    bool? asBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase().trim();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return null;
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final cardId       = pick<dynamic>(['card_id', 'cardId'])?.toString() ?? '';
    final customerId   = pick<dynamic>(['customer_id', 'customerId'])?.toString() ?? '';
    final accountId    = pick<dynamic>(['account_id', 'accountId'])?.toString() ?? '';
    final cardNumber   = pick<dynamic>(['card_number', 'cardNumber'])?.toString() ?? '';

    return DebitCard(
      cardId: cardId,
      customerId: customerId,
      accountId: accountId,
      cardNumber: cardNumber,
      cardBrand: pick<String>(['card_brand', 'cardBrand']),
      cardType: pick<String>(['card_type', 'cardType']),
      isActive: asBool(pick<dynamic>(['is_active', 'isActive'])),
      isBlocked: asBool(pick<dynamic>(['is_blocked', 'isBlocked'])),
      blockReason: pick<String>(['block_reason', 'blockReason']),
      dailyTransactionLimit: asInt(pick<dynamic>(['daily_transaction_limit', 'dailyTransactionLimit'])),
      validThrough: pick<String>(['valid_through', 'validThrough']),
    );
  }

  Map<String, dynamic> toJson() => {
        'card_id': cardId,
        'customer_id': customerId,
        'account_id': accountId,
        'card_number': cardNumber,
        'card_brand': cardBrand,
        'card_type': cardType,
        'is_active': isActive,
        'is_blocked': isBlocked,
        'block_reason': blockReason,
        'daily_transaction_limit': dailyTransactionLimit,
        'valid_through': validThrough,
      };

  /// UI için: **** **** **** 1234
  String get maskedNumber {
    if (cardNumber.isEmpty) return '';
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return cleaned;
    final last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }
}
