import 'package:flutter/material.dart';
import 'package:interbank/utils/colors.dart'; // Renk paletimizi import ediyoruz
import 'home_screen.dart'; // Giriş yapınca gidilecek ekranı import ediyoruz

class ModernLoginScreen extends StatelessWidget {
  const ModernLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Profil ve Hoş Geldiniz
            Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child:
                      Icon(Icons.person_outline, size: 50, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  "Hoş Geldiniz!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Muhammed Said Öztürk",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Giriş Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Center(
                  child: Text(
                    "GİRİŞ YAPIN",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Farklı Kullanıcı ile Giriş Yapın",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            // Kampanya Kartları
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCampaignCard(
                      "%45 Hoş Geldin Faizi", Icons.percent, Colors.orange),
                  _buildCampaignCard(
                      "2,99 Faiz Fırsatı", Icons.trending_down, Colors.green),
                  _buildCampaignCard(
                      "Kredi Notunu Gör", Icons.analytics, Colors.purple),
                  _buildCampaignCard(
                      "Güvence Yanınızda", Icons.verified, Colors.blue),
                ],
              ),
            ),
            const Spacer(),
            // Alt Menü
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BottomMenuItem(
                      icon: Icons.flash_on, label: "FAST İşlemleri"),
                  _BottomMenuItem(icon: Icons.assignment, label: "Başvurular"),
                  _BottomMenuItem(icon: Icons.menu, label: "Menü"),
                  _BottomMenuItem(
                      icon: Icons.home_work, label: "Şubesiz İşlem"),
                  _BottomMenuItem(icon: Icons.campaign, label: "Kampanyalar"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCampaignCard(String title, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BottomMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BottomMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
