import 'package:flutter/material.dart';

class BasvurularPage extends StatelessWidget {
  const BasvurularPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> menuItems = [
      "Hesap Açılışı",
      "Hesaplamalar",
      "Kart Başvurusu",
      "Kredi Başvurusu",
      "Üye İşyeri Başvurusu",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Üst mavi başlık
          Container(
            height: 90,
            color: const Color(0xFF0077C8),
            padding: const EdgeInsets.only(top: 40, left: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              "BAŞVURULAR",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Süper Limit banner
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Süper Limit",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Size özel tekliflere hemen göz atın.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),

          // Menü listesi
          Expanded(
            child: ListView.separated(
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(menuItems[index]),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Şimdilik pasif
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
