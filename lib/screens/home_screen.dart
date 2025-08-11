import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0077C8); // DenizBank mavisi
  static const background = Color(0xFFF5F6FA);
  static const textDark = Color(0xFF222222);
  static const textLight = Colors.white;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Asistan pozisyonu
  double assistantX = 200;
  double assistantY = 500;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Üst Mavi Alan
          Container(
            height: screenHeight * 0.35,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Menü
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.menu, color: Colors.white),
                    const Text(
                      "HESAPLAR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                // Hesap Bilgisi
                const Text(
                  "00000001 - 351 / Intertech Kurtköy",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Kullanılabilir Bakiye",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Text(
                  "0,00 TL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          // Alt Kısım
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.28),
            child: Column(
              children: [
                // Butonlar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.send, "Para Gönder"),
                      _buildActionButton(Icons.receipt_long, "Fatura Öde"),
                      _buildActionButton(Icons.qr_code, "QR İşlemleri"),
                      _buildActionButton(Icons.share, "IBAN Paylaş"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Reklam Kartı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.security, color: AppColors.primary),
                      title: Text(
                        "Acil Güvence FKS ile Risklere Karşı Hazırlıklı Olun!",
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        "Güvence Altına Alın",
                        style:
                            TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
                const Spacer(),
                // Alt Menü
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _BottomNavItem(icon: Icons.home, label: "Ana Sayfa"),
                      _BottomNavItem(
                          icon: Icons.assignment, label: "Başvurular"),
                      _BottomNavItem(icon: Icons.settings, label: "Menü"),
                      _BottomNavItem(icon: Icons.send, label: "Para Gönder"),
                      _BottomNavItem(icon: Icons.payment, label: "Ödeme Yap"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dijital Asistan (sürüklenebilir)
          Positioned(
            left: assistantX,
            top: assistantY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  assistantX += details.delta.dx;
                  assistantY += details.delta.dy;
                });
              },
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.smart_toy,
                        size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Asistan",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Buton Widget'ı
  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 24,
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomNavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
