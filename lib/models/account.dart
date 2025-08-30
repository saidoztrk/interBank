// account.dart
class Account {
  final String accountId;
  final String type;
  final String currency;
  final double balance;

  Account({
    required this.accountId,
    required this.type,
    required this.currency,
    required this.balance,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    accountId: j['accountId'].toString(),
    type: j['type'] ?? '',
    currency: j['currency'] ?? 'TRY',
    balance: (j['balance'] is num) ? (j['balance'] as num).toDouble() : double.tryParse(j['balance'].toString()) ?? 0.0,
  );
}
