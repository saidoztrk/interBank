// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

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
  // Asistan balonu
  double assistantX = 200;
  double assistantY = 500;
  final double assistantRadius = 34; // balon yarıçapı
  bool assistantVisible = true;

  // Drag durumları
  bool _showTrash = false;
  bool _overTrash = false;
  bool _dragging = false;

  // Nefes (pulse) animasyonu
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

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
    final Size size = MediaQuery.of(context).size;
    final double screenW = size.width;
    final double screenH = size.height;

    // Çöp kutusu alanı (ekran alt-orta)
    final double trashSize = 90;
    final Rect trashRect = Rect.fromCenter(
      center: Offset(screenW / 2, screenH - 40 - trashSize / 2),
      width: trashSize,
      height: trashSize,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Üst dalgalı pastel header
          _buildWavyHeader(context),

          // İçerik
          Padding(
            padding: EdgeInsets.only(top: screenH * 0.27),
            child: Column(
              children: [
                _buildGreetingCard(),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 14),
                _buildFunStrip(),
                const Spacer(),
                _buildBottomBar(onMenuTap: _openMenuQuickActions),
              ],
            ),
          ),

          // Dijital Asistan (sürüklenebilir + pulse)
          if (assistantVisible)
            Positioned(
              left: assistantX,
              top: assistantY,
              child: GestureDetector(
                onPanStart: (_) {
                  setState(() {
                    _showTrash = true;
                    _dragging = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    assistantX += details.delta.dx;
                    assistantY += details.delta.dy;
                    _clampAssistant(size);
                    // Asistan merkez noktası çöp alanında mı?
                    final Offset center = Offset(
                      assistantX + assistantRadius,
                      assistantY + assistantRadius,
                    );
                    _overTrash = trashRect.contains(center);
                  });
                },
                onPanEnd: (_) {
                  if (_overTrash) {
                    setState(() {
                      assistantVisible = false;
                      _showTrash = false;
                      _overTrash = false;
                      _dragging = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Asistan gizlendi. Menüden tekrar açabilirsiniz.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    setState(() {
                      _showTrash = false;
                      _overTrash = false;
                      _dragging = false;
                    });
                  }
                },
                onTap: () => Navigator.pushNamed(context, '/chat'),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final scale = _dragging ? 1.0 : _pulse.value;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      // Gölge + dairesel avatar (içerik contain + padding)
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _assistantBubbleImage(radius: assistantRadius),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Asistan",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Çöp kutusu overlay (drag sırasında)
          if (_showTrash)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: trashSize,
                  height: trashSize,
                  decoration: BoxDecoration(
                    color: _overTrash ? Colors.red : Colors.black12,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _overTrash ? Colors.redAccent : Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.delete,
                    size: 36,
                    color: _overTrash ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Dalgalı başlık alanı
  Widget _buildWavyHeader(BuildContext context) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        height: 260,
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
            // başlık içerik
            Padding(
              padding: const EdgeInsets.only(top: 54, left: 20, right: 20),
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
    final greet = hour < 12
        ? "Günaydın"
        : hour < 18
            ? "İyi günler"
            : "İyi akşamlar";
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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

  // Hızlı işlemler (pastel)
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

  // Eğlenceli kartlar (yatay)
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

  // Alt bar – Menü item’ı asistan kısa yolunu açar
  Widget _buildBottomBar({required VoidCallback onMenuTap}) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
              icon: Icons.home_rounded, label: "Ana Sayfa", onTap: () {}),
          _BottomNavItem(
              icon: Icons.assignment, label: "Başvurular", onTap: () {}),
          _BottomNavItem(icon: Icons.settings, label: "Menü", onTap: onMenuTap),
          _BottomNavItem(icon: Icons.send, label: "Para Gönder", onTap: () {}),
          _BottomNavItem(icon: Icons.payment, label: "Ödeme Yap", onTap: () {}),
        ],
      ),
    );
  }

  // Menü hızlı işlemler
  void _openMenuQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('Asistan sohbeti'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Asistan balonunu göster'),
                  subtitle: const Text('Ekranda görünmüyorsa geri getir'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => assistantVisible = true);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  // Asistan balonu resmi: tam sığdır (contain) + iç padding
  Widget _assistantBubbleImage({required double radius}) {
    final double size = radius * 2;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white, // beyaz zemin
        shape: BoxShape.circle,
      ),
      padding:
          const EdgeInsets.all(8), // kenarlara değmesin; istersen artır/azalt
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/chatbot/kalpli.png',
          fit: BoxFit.contain, // oranı koruyarak çemberin içine sığdırır
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  // Asistanı ekran sınırları içinde tut
  void _clampAssistant(Size size) {
    final double maxX = size.width - assistantRadius * 2;
    final double maxY =
        size.height - assistantRadius * 2 - 62; // alt bar kadar boşluk
    if (assistantX < 8) assistantX = 8;
    if (assistantY < 8) assistantY = 8;
    if (assistantX > maxX - 8) assistantX = maxX - 8;
    if (assistantY > maxY - 8) assistantY = maxY - 8;
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
