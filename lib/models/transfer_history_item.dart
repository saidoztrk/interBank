// lib/models/transfer_history_item.dart
// Erenay tarafından eklendi: Home geçmişi için transfer tabanlı model
// Kaynak örnek (Swagger):
// {
//   "TransferId": 34,
//   "SenderAccountId": 91001,
//   "ReceiverAccountId": 91002,
//   "Amount": 1000,
//   "Currency": "TRY",
//   "Description": "test havale",
//   "TransferDate": "2025-09-02T15:34:17.000596",
//   "Status": "Posted"
// }

/// IN = gelen, OUT = giden
enum TransferDirection { IN, OUT }

class TransferHistoryItem {
  /// Uygulama içi benzersiz kimlik (stringleştirilmiş TransferId)
  final String id;

  /// Şimdilik sabit: "transfer" (ileride "bill"/"payment" ile genişleyebilir)
  final String type;

  /// Kart başlığı (öncelik: Description; boşsa karşı hesap no)
  final String title;

  /// Tutar (pozitif değer; OUT/IN görselleştirmeyi UI yapar)
  final double amount;

  /// Para birimi (TRY, USD, …)
  final String currency;

  /// Yön: aktif hesaba göre OUT/IN
  final TransferDirection direction;

  /// Durum (ör. "Posted")
  final String status;

  /// Gerçekleşme zamanı
  final DateTime occurredAt;

  /// Karşı taraf hesap numarası (stringleştirilmiş)
  final String counterparty;

  /// Debug/troubleshoot için ham JSON (opsiyonel)
  final Map<String, dynamic>? raw;

  /// API alanları: (UI’de ihtiyaç olursa)
  final String? senderAccountId;
  final String? receiverAccountId;

  const TransferHistoryItem({
    required this.id,
    this.type = 'transfer',
    required this.title,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.status,
    required this.occurredAt,
    required this.counterparty,
    this.raw,
    this.senderAccountId,
    this.receiverAccountId,
  });

  // --------------------------
  // Factory: Swagger TRANSFER → TransferHistoryItem
  // activeAccount: login sonrası seçili/aktif hesap (örn. "91001" ya da 91001)
  // --------------------------
  factory TransferHistoryItem.fromTransferJson(
    Map<String, dynamic> json, {
    required dynamic activeAccount,
  }) {
    final transferId = _pick(json, ['TransferId', 'transferId', 'transfer_id']);
    final sender = _pick(json,
        ['SenderAccountId', 'senderAccountId', 'sender_account_id']);
    final receiver = _pick(json, [
      'ReceiverAccountId',
      'receiverAccountId',
      'receiver_account_id'
    ]);
    final amountRaw = _pick(json, ['Amount', 'amount']);
    final currency =
        (_pick(json, ['Currency', 'currency']) ?? 'TRY').toString();
    final description =
        (_pick(json, ['Description', 'description']) ?? '').toString();
    final transferDateStr =
        _pick(json, ['TransferDate', 'transferDate', 'transfer_date'])
            ?.toString();
    final status = (_pick(json, ['Status', 'status']) ?? '').toString();

    final senderNorm = _normalizeAcc(sender);
    final receiverNorm = _normalizeAcc(receiver);
    final activeNorm = _normalizeAcc(activeAccount);

    // Yön tayini
    final dir = (activeNorm.isNotEmpty && activeNorm == senderNorm)
        ? TransferDirection.OUT
        : TransferDirection.IN;

    // Karşı taraf
    final counterparty = dir == TransferDirection.OUT ? receiverNorm : senderNorm;

    // Title yedeği
    final title = (description.isNotEmpty) ? description : counterparty;

    // Tutar
    final amt = _toDouble(amountRaw);

    // Tarih
    final occurredAt =
        transferDateStr != null ? DateTime.tryParse(transferDateStr) : null;

    return TransferHistoryItem(
      id: (transferId ?? '').toString(),
      title: title,
      amount: amt ?? 0.0,
      currency: currency,
      direction: dir,
      status: status.isEmpty ? 'Posted' : status,
      occurredAt: occurredAt ?? DateTime.now(),
      counterparty: counterparty,
      raw: Map<String, dynamic>.from(json),
      senderAccountId: senderNorm.isEmpty ? null : senderNorm,
      receiverAccountId: receiverNorm.isEmpty ? null : receiverNorm,
    );
    // Log önerisi (ekleme yeri: mapper çağrıldığı yer)
    // [Erenay][MAP][HISTORY] mapped id=$transferId dir=${dir.name} amt=$amt ccy=$currency
  }

  // Basit JSON (UI/Cache amaçlı)
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'amount': amount,
        'currency': currency,
        'direction': direction.name,
        'status': status,
        'occurredAt': occurredAt.toIso8601String(),
        'counterparty': counterparty,
        'senderAccountId': senderAccountId,
        'receiverAccountId': receiverAccountId,
      };

  // UI yardımcıları
  bool get isIncome => direction == TransferDirection.IN;
  String get sign => isIncome ? '+' : '-';

  TransferHistoryItem copyWith({
    String? id,
    String? type,
    String? title,
    double? amount,
    String? currency,
    TransferDirection? direction,
    String? status,
    DateTime? occurredAt,
    String? counterparty,
    Map<String, dynamic>? raw,
    String? senderAccountId,
    String? receiverAccountId,
  }) {
    return TransferHistoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      occurredAt: occurredAt ?? this.occurredAt,
      counterparty: counterparty ?? this.counterparty,
      raw: raw ?? this.raw,
      senderAccountId: senderAccountId ?? this.senderAccountId,
      receiverAccountId: receiverAccountId ?? this.receiverAccountId,
    );
  }
}

// --------------------------
// Yardımcılar (tolerant parser)
// --------------------------

/// Çoklu anahtardan ilk dolu değeri döndürür.
dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

/// "91001", 91001, "TR..91001" → "91001"
String _normalizeAcc(dynamic v) {
  if (v == null) return '';
  final s = v.toString();
  final digits = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).join();
  return digits;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}
