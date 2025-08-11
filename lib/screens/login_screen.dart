import 'package:flutter/material.dart';
import 'home_screen.dart';

class BankStyleLoginScreen extends StatefulWidget {
  const BankStyleLoginScreen({super.key});

  @override
  State<BankStyleLoginScreen> createState() => _BankStyleLoginScreenState();
}

class _BankStyleLoginScreenState extends State<BankStyleLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username == "intertech" && password == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı adı veya şifre hatalı!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Kaydırılabilir yapıldı
        child: Column(
          children: [
            // ÜST MAVİ ALAN
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 30), // biraz küçültüldü
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35, // küçültüldü
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline,
                        size: 45, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hoş Geldiniz!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18, // küçültüldü
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "TEAM 1", // değiştirildi
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 40), // küçültüldü
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "GİRİŞ YAP",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Farklı Kullanıcı ile Giriş Yapın",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // KULLANICI ADI & ŞİFRE ALANI
            Padding(
              padding: const EdgeInsets.all(14.0), // küçültüldü
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Kullanıcı Adı",
                      prefixIcon:
                          const Icon(Icons.person_outline, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // KAMPANYA KARTLARI
            SizedBox(
              height: 100, // küçültüldü
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

            const SizedBox(height: 10), // boşluk eklendi

            // ALT MENÜ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                  _BottomMenuItem(icon: Icons.flash_on, label: "FAST"),
                  _BottomMenuItem(icon: Icons.assignment, label: "Başvuru"),
                  _BottomMenuItem(icon: Icons.menu, label: "Menü"),
                  _BottomMenuItem(icon: Icons.home_work, label: "Şubesiz"),
                  _BottomMenuItem(icon: Icons.campaign, label: "Kampanya"),
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
      width: 120, // küçültüldü
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
