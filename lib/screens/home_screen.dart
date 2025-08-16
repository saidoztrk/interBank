// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

class AppColors {
  static const background = Color(0xFFF8FAFF);
  static const primary = Color(0xFF7BC6FF); // pastel mavi
  static const primary2 = Color(0xFFB2F0FF);
  static const textDark = Color(0xFF233041);
  static const textSub = Color(0xFF5D6B82);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Nefes (pulse) animasyonu sadece ortadaki kaptan için
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Kaptan boyutları
  static const double _captainRadius = 40;                    // yarıçap
  static const double _captainDiameter = _captainRadius * 2;  // 80 px

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenH = size.height;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Üst dalgalı pastel header
          _buildWavyHeader(context),

          // İçerik (üst başlıktan sonra)
          Padding(
            padding: EdgeInsets.only(top: screenH * 0.27),
            child: Column(
              children: [
                _buildGreetingCard(),
                const SizedBox(height: 16),
                _buildQuickActions(),  // <-- ÜSTTEKİ SEÇENEKLER KALDI
                const SizedBox(height: 14),
                _buildFunStrip(),      // <-- KARTLAR KALDI
                const Spacer(),
                // Alt bar (ortada kaptan için boşluklu)
                _buildBottomBar(bottomSafe: bottomSafe),
              ],
            ),
          ),

          // Ortadaki büyük Kaptan butonu (sabit, alt barda ortalanmış)
          Positioned(
            left: 0,
            right: 0,
            // Alt bara yarı taşacak şekilde, overflow riskini azaltan formül
            bottom: bottomSafe + (62 - _captainDiameter / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                    child: Container(
                      width: _captainDiameter,
                      height: _captainDiameter,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: GifView.asset(
                          'lib/assets/gifs/rudder.gif',
                          frameRate: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Kaptan",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,      // daha kalın
                    color: AppColors.primary,          // mavi
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dalgalı başlık alanı (çentik uyumlu)
  Widget _buildWavyHeader(BuildContext context) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // dekoratif kabarcıklar
            Positioned(
              top: 36,
              left: -10,
              child: _bubble(70, Colors.white.withOpacity(.18)),
            ),
            Positioned(
              top: 20,
              right: -6,
              child: _bubble(46, Colors.white.withOpacity(.16)),
            ),
            Positioned(
              bottom: 18,
              right: 40,
              child: _bubble(28, Colors.white.withOpacity(.14)),
            ),
            // başlık içerik — SafeArea ile çentik uyumlu
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.menu, color: Colors.white),
                    Text(
                      "İnterBank",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: .2,
                      ),
                    ),
                    Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Selamlama kartı
  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? "Günaydın" : hour < 18 ? "İyi günler" : "İyi akşamlar";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text("👋", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Team 1'e selam!",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Bugün neleri hallediyoruz? 😎",
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                greet,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hızlı işlemler (pastel) — KALDI
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionChip(Icons.send, "Para Gönder", Colors.pinkAccent),
          _actionChip(Icons.receipt_long, "Fatura Öde", Colors.amber),
          _actionChip(Icons.qr_code, "QR İşlemleri", Colors.teal),
          _actionChip(Icons.share, "IBAN Paylaş", Colors.deepPurpleAccent),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Eğlenceli kartlar (yatay) — KALDI
  Widget _buildFunStrip() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _funCard("🎯 Hedef: %45", "Hoş geldin faizi",
              [Colors.orange, Colors.deepOrangeAccent]),
          _funCard("📉 2,99", "Faiz fırsatı", [Colors.green, Colors.teal]),
          _funCard("📊 Notunu Gör", "Kredi notun hazır",
              [Colors.purple, Colors.indigo]),
          _funCard("🛡️ Güvende", "Yanınızdayız",
              [Colors.blue, Colors.lightBlueAccent]),
        ],
      ),
    );
  }

  Widget _funCard(String title, String sub, List<Color> gr) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gr),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              )),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Detay",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Alt bar – yalnızca: solda Hesabım, ortada Kaptan için boşluk, sağda Çıkış Yap
  Widget _buildBottomBar({required double bottomSafe}) {
    return Container(
      height: 62 + bottomSafe,
      padding: EdgeInsets.only(bottom: bottomSafe > 0 ? bottomSafe - 2 : 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.person, label: "Hesabım", onTap: () {
            // TODO: Hesabım sayfasına git
          }),
          SizedBox(width: _captainDiameter + 20), // Ortadaki Kaptan için boşluk
          _BottomNavItem(icon: Icons.exit_to_app, label: "Çıkış Yap", onTap: () {
            // TODO: Çıkış işlemi
          }),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// Dalgalı kesim (ClipPath) için custom clipper
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path()..lineTo(0, size.height - 60);
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 30);
    final secondControlPoint = Offset(size.width * 0.75, size.height - 90);
    final secondEndPoint = Offset(size.width, size.height - 50);

    path
      ..quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
          firstEndPoint.dx, firstEndPoint.dy)
      ..quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
          secondEndPoint.dx, secondEndPoint.dy)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
