import 'package:flutter/material.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text("KAMPANYALAR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // Şimdilik pasif
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst yatay kampanya butonları
          Container(
            height: 95,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTopCampaignItem("%45 Hoş Geldin Faizi", Colors.red),
                _buildTopCampaignItem("2,99 Faiz Fırsatı", Colors.blue),
                _buildTopCampaignItem("Restoran ve Market", Colors.orange),
                _buildTopCampaignItem("Sosyopix İndirim", Colors.purple),
                _buildTopCampaignItem("Güvence Yanınızda", Colors.green),
              ],
            ),
          ),

          // Gövde kampanya kartları
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildCampaignCard(
                  title:
                      "MobilDeniz'den DenizBanklı Olanlara 1 Yıl Ücretsiz EFT ve Havale Fırsatı!",
                  imageUrl:
                      "https://via.placeholder.com/300x150.png?text=Kampanya+1",
                  button1: "HEMEN KATIL",
                  button2: "KAMPANYA DETAYLARI",
                ),
                const SizedBox(height: 10),
                _buildCampaignCard(
                  title:
                      "125.000 TL İhtiyaç Krediniz %2,99 Faiz Oranı ile Sizi Bekliyor!",
                  imageUrl:
                      "https://via.placeholder.com/300x150.png?text=Kampanya+2",
                  button1: "HEMEN BAŞVUR",
                  button2: "DETAYLAR",
                ),
              ],
            ),
          ),

          // Alt Menü
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _BottomMenuItem(icon: Icons.flash_on, label: "FAST İşlemleri"),
                _BottomMenuItem(icon: Icons.assignment, label: "Başvurular"),
                _BottomMenuItem(icon: Icons.menu, label: "MENÜ"),
                _BottomMenuItem(icon: Icons.home_work, label: "Şubesiz İşlem"),
                _BottomMenuItem(icon: Icons.campaign, label: "Kampanyalar"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yatay kampanya butonu
  Widget _buildTopCampaignItem(String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 26,
            child: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Kampanya kartı
  Widget _buildCampaignCard({
    required String title,
    required String imageUrl,
    required String button1,
    required String button2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {}, // Şimdilik pasif
                child:
                    Text(button1, style: const TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () {}, // Şimdilik pasif
                child:
                    Text(button2, style: const TextStyle(color: Colors.blue)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Alt Menü Item
class _BottomMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BottomMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: Colors.blue),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
