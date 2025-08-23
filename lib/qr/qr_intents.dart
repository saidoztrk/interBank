// lib/qr/qr_intents.dart

// Sohbet içi eylem/niyet tespiti
enum ChatActionType { qrPay }

class ChatAction {
  final String label;
  final ChatActionType action;
  const ChatAction({required this.label, required this.action});
}

/// Türkçe aksan/işaret normalize eder ve lower-case yapar.
String _normalizeTr(String input) {
  final map = {
    'ç': 'c', 'Ç': 'c',
    'ğ': 'g', 'Ğ': 'g',
    'ı': 'i', 'İ': 'i',
    'ö': 'o', 'Ö': 'o',
    'ş': 's', 'Ş': 's',
    'ü': 'u', 'Ü': 'u',
  };
  final sb = StringBuffer();
  for (final ch in input.runes) {
    final s = String.fromCharCode(ch);
    sb.write(map[s] ?? s);
  }
  return sb.toString().toLowerCase().trim();
}

/// Kullanıcı metninin QR ile ödeme niyeti içerip içermediğini tespit eder.
bool isQrPayIntent(String text) {
  final t = _normalizeTr(text);
  final patterns = <String>[
    'qr','qr ode','qr ile ode','qr odeme','karekod','kod okut',
    'qr okut','qr ile odeme','qr odeme yap','karekod ode',
  ];
  return patterns.any((p) => t.contains(p));
}

// ===== QR veri modeli =====
class QRPaymentData {
  final String receiverName;
  final String receiverIban;
  final double? amount;
  final String? note;

  QRPaymentData({
    required this.receiverName,
    required this.receiverIban,
    this.amount,
    this.note,
  });

  @override
  String toString() =>
      'QRPaymentData(receiverName: $receiverName, receiverIban: $receiverIban, amount: $amount, note: $note)';
}

// ===== Basit DEMO parser =====
// Örnek format: TRQR|RECEIVER=Ad Soyad|IBAN=TRxx...|AMOUNT=150.75|NOTE=Açıklama
QRPaymentData? tryParseQrPayment(String raw) {
  if (raw.isEmpty) return null;

  if (raw.startsWith('TRQR|')) {
    String? name, iban, note;
    double? amount;
    final parts = raw.split('|').skip(1);
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final key = kv[0].toUpperCase().trim();
      final val = kv[1].trim();
      switch (key) {
        case 'RECEIVER': name = val; break;
        case 'IBAN':     iban = val; break;
        case 'AMOUNT':   amount = double.tryParse(val.replaceAll(',', '.')); break;
        case 'NOTE':     note = val; break;
      }
    }
    if (name != null && iban != null) {
      return QRPaymentData(
        receiverName: name,
        receiverIban: iban,
        amount: amount,
        note: note,
      );
    }
    return null;
  }

  // Fallback: metin içinde IBAN ara
  final ibanRegex = RegExp(r'\bTR[0-9A-Z]{24}\b', caseSensitive: false);
  final match = ibanRegex.firstMatch(raw.toUpperCase());
  if (match != null) {
    return QRPaymentData(
      receiverName: 'Bilinmiyor',
      receiverIban: match.group(0)!,
      amount: null,
      note: null,
    );
  }
  return null;
}
