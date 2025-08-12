import 'package:flutter/material.dart';

class FastIslemleriPage extends StatelessWidget {
  const FastIslemleriPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> menuItems = [
      "FAST TR Karekod ile Öde",
      "Para Gönder",
      "Ödeme İste",
      "FAST TR Karekod Oluştur",
      "Kolay Adres Yönetimi",
      "Güvenli Ödeme İşlemi",
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
              "FAST İŞLEMLERİ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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

          // Alt FAST logosu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: const [
                Icon(Icons.flash_on, color: Colors.blue, size: 30),
                SizedBox(height: 4),
                Text(
                  "fast",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
