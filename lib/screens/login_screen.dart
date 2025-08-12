// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart'; // ✅ doğrudan HomeScreen'e gideceğiz

class BankStyleLoginScreen extends StatefulWidget {
  const BankStyleLoginScreen({super.key});

  @override
  State<BankStyleLoginScreen> createState() => _BankStyleLoginScreenState();
}

class _BankStyleLoginScreenState extends State<BankStyleLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == "intertech" && password == "123456") {
      // ✅ Named route yerine doğrudan HomeScreen'e git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D47A1),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: const _BottomBar(),
        body: Column(
          children: [
            // ÜST MAVİ ALAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline, size: 45, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hoş Geldiniz!",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text("TEAM 1", style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: const Text("GİRİŞ YAP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

            // ORTA İÇERİK — kaydırılabilir
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // KULLANICI ADI & ŞİFRE
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: "Kullanıcı Adı",
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Şifre",
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // KAMPANYA KARTLARI
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        children: const [
                          _CampaignCard(title: "%45 Hoş Geldin Faizi", icon: Icons.percent, color: Color(0xFFFFB020)),
                          _CampaignCard(title: "2,99 Faiz Fırsatı", icon: Icons.trending_down, color: Color(0xFF17B26A)),
                          _CampaignCard(title: "Kredi Notunu Gör", icon: Icons.analytics, color: Color(0xFF7A5AF8)),
                          _CampaignCard(title: "Güvence Yanınızda", icon: Icons.verified, color: Color(0xFF2D7DFF)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Bileşenler ----

class _CampaignCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _CampaignCard({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomMenuItem(icon: Icons.flash_on, label: "FAST"),
          _BottomMenuItem(icon: Icons.assignment, label: "Başvuru"),
          _BottomMenuItem(icon: Icons.menu, label: "Menü"),
          _BottomMenuItem(icon: Icons.home_work, label: "Şubesiz"),
          _BottomMenuItem(icon: Icons.campaign, label: "Kampanya"),
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
