import 'package:flutter/material.dart';

class QrSummaryCard extends StatelessWidget {
  final String receiver;
  final String iban;
  final double? amount;
  final String? note;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const QrSummaryCard({
    super.key,
    required this.receiver,
    required this.iban,
    this.amount,
    this.note,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Alıcı: $receiver", style: const TextStyle(fontWeight: FontWeight.w600)),
          Text("IBAN: $iban"),
          if (amount != null) Text("Tutar: ${amount!.toStringAsFixed(2)} TL"),
          if (note != null && note!.isNotEmpty) Text("Açıklama: $note"),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: onConfirm, child: const Text("Onayla")),
              const SizedBox(width: 8),
              TextButton(onPressed: onCancel, child: const Text("İptal")),
            ],
          ),
        ]),
      ),
    );
  }
}
