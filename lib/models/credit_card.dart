// lib/models/credit_card.dart
class CreditCard {
  // --- Zorunlu (id’ler & numara) ---
  final String cardId;        // "3006"
  final String customerId;    // "9001"
  final String accountId;     // "91001"
  final String cardNumber;    // "5521...."

  // --- Kart bilgileri ---
  final String? cardBrand;    // "VISA" | "MASTERCARD" | "TROY" | ...
  final String? cardType;     // "credit" vb.
  final bool? isActive;       // 1/0 || true/false
  final bool? isBlocked;      // 1/0 || true/false
  final String? blockReason;

  // --- Limit & borç bilgileri ---
  final double? currentDebt;           // current_debt
  final double? creditLimit;           // credit_limit (toplam limit)
  final double? availableLimit;        // available_limit
  final double? increaseableLimit;     // increaseable_limit / increasable_limit
  final double? decreaseableLimit;     // decreaseable_limit / decreasable_limit
  final double? cashWithdrawalLimit;   // cash_withdrawal_limit / withdraw_limit / cash_limit
  final double? dailyLimit;            // daily_limit (varsa)

  // --- Ödeme & tarih ---
  final double? minPayment;    // min_payment
  final String? validThrough;  // "2029-02-02"
  final String? maturityDate;  // "2025-02-02" (hesap kesim/son ödeme gibi alan)
  final String? autopay;       // "on"/"off" veya başka bir temsil

  CreditCard({
    required this.cardId,
    required this.customerId,
    required this.accountId,
    required this.cardNumber,
    this.cardBrand,
    this.cardType,
    this.isActive,
    this.isBlocked,
    this.blockReason,
    this.currentDebt,
    this.creditLimit,
    this.availableLimit,
    this.increaseableLimit,
    this.decreaseableLimit,
    this.cashWithdrawalLimit,
    this.dailyLimit,
    this.minPayment,
    this.validThrough,
    this.maturityDate,
    this.autopay,
  });

  // -------- Parsing yardımcıları --------
  static T? _pick<T>(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k] as T;
    }
    return null;
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == '1' || s == 'true' || s == 'yes' || s == 'on') return true;
    if (s == '0' || s == 'false' || s == 'no'  || s == 'off') return false;
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final fixed = v.toString().replaceAll(',', '.');
    return double.tryParse(fixed);
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory CreditCard.fromJson(Map<String, dynamic> j) {
    final cardId     = _pick<dynamic>(j, ['card_id', 'cardId'])?.toString() ?? '';
    final customerId = _pick<dynamic>(j, ['customer_id', 'customerId'])?.toString() ?? '';
    final accountId  = _pick<dynamic>(j, ['account_id', 'accountId'])?.toString() ?? '';
    final cardNumber = _pick<dynamic>(j, ['card_number', 'cardNumber'])?.toString() ?? '';

    return CreditCard(
      cardId: cardId,
      customerId: customerId,
      accountId: accountId,
      cardNumber: cardNumber,
      cardBrand: _pick<String>(j, ['card_brand', 'cardBrand']),
      cardType:  _pick<String>(j, ['card_type', 'cardType']),
      isActive:  _asBool(_pick<dynamic>(j, ['is_active', 'isActive'])),
      isBlocked: _asBool(_pick<dynamic>(j, ['is_blocked', 'isBlocked'])),
      blockReason: _pick<String>(j, ['block_reason', 'blockReason']),
      currentDebt: _asDouble(_pick<dynamic>(j, ['current_debt', 'currentDebt'])),
      creditLimit: _asDouble(_pick<dynamic>(j, ['credit_limit', 'creditLimit'])),
      availableLimit: _asDouble(_pick<dynamic>(j, ['available_limit', 'availableLimit'])),
      increaseableLimit: _asDouble(_pick<dynamic>(j, ['increaseable_limit', 'increasable_limit', 'increaseableLimit', 'increasableLimit'])),
      decreaseableLimit: _asDouble(_pick<dynamic>(j, ['decreaseable_limit', 'decreasable_limit', 'decreaseableLimit', 'decreasableLimit'])),
      cashWithdrawalLimit: _asDouble(_pick<dynamic>(j, ['cash_withdrawal_limit', 'withdraw_limit', 'cash_limit', 'cashWithdrawalLimit'])),
      dailyLimit: _asDouble(_pick<dynamic>(j, ['daily_limit', 'dailyLimit'])),
      minPayment: _asDouble(_pick<dynamic>(j, ['min_payment', 'minPayment'])),
      validThrough: _pick<String>(j, ['valid_through', 'validThrough']),
      maturityDate: _pick<String>(j, ['maturity_date', 'maturityDate']),
      autopay: _pick<String>(j, ['autopay', 'autoPay', 'auto_pay']),
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
        'current_debt': currentDebt,
        'credit_limit': creditLimit,
        'available_limit': availableLimit,
        'increaseable_limit': increaseableLimit,
        'decreaseable_limit': decreaseableLimit,
        'cash_withdrawal_limit': cashWithdrawalLimit,
        'daily_limit': dailyLimit,
        'min_payment': minPayment,
        'valid_through': validThrough,
        'maturity_date': maturityDate,
        'autopay': autopay,
      };

  /// UI için: **** **** **** 9018
  String get maskedNumber {
    if (cardNumber.isEmpty) return '';
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return cleaned;
    final last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }
}
