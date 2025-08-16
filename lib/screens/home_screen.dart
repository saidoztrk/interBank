// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/captain_menu_icon.dart'; // ortadaki kaptan şapkası (peek animasyonlu)

class AppColors {
  static const background = Color(0xFF0A1628); // Denizci mavisi koyu
  static const primary = Color(0xFF1E3A8A); // Kaptan mavisi
  static const primary2 = Color(0xFF3B82F6); // Açık deniz mavisi
  static const accent = Color(0xFFFFD700); // Altın sarısı (kaptan detayları)
  static const textLight = Color(0xFFE5E7EB); // Açık gri metin
  static const textSub = Color(0xFFD1D5DB); // Alt metin
  static const cardBg = Color(0xFF1F2937); // Kart arka planı
  static const bar = Colors.white; // Alt bar
}

// Alt bar PNG ikonları (klasör yapına göre)
const String kIconHome = 'lib/assets/images/captain/home/home.png';
const String kIconApps = 'lib/assets/images/captain/home/apps.png';
const String kIconSend = 'lib/assets/images/captain/home/send.png';
const String kIconPay = 'lib/assets/images/captain/home/pay.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Kaptan balonu (draggable) - varsayılan pozisyon
  double captainX = 50; // Başlangıç pozisyonu sola yakın
  double captainY = 300; // Başlangıç pozisyonu orta yükseklik
  final double captainRadius = 34;
  bool captainVisible = true;
  bool isDragging = false;
  bool showTrashCan = false;

  // Varsayılan pozisyon sabitleri
  static const double defaultCaptainX = 50;
  static const double defaultCaptainY = 300;

  // Nefes (pulse) animasyonu
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Alt bar seçili tab
  int _tab = 0;

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

  bool get _captainHidden => !captainVisible;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenH = size.height;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ------- GÖVDE -------
      body: Stack(
        clipBehavior: Clip.none, // balonun kesilmesini engelle
        children: [
          _buildWavyHeader(context),
          Padding(
            padding: EdgeInsets.only(top: screenH * 0.20),
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildGreetingCard(),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 10),
                  _buildFunStrip(),
                ],
              ),
            ),
          ),

          // Kaptan balonu (geliştirilmiş drag + pulse)
          if (captainVisible)
            Positioned(
              left: captainX,
              top: captainY,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    isDragging = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    captainX += details.delta.dx;
                    captainY += details.delta.dy;
                    _clampCaptain(size);

                    // Çöp kutusunu göster/gizle (alt %20'lik kısımda)
                    showTrashCan = captainY > size.height * 0.75;
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    isDragging = false;
                    // Eğer çöp kutusu alanındaysa kaldır
                    if (showTrashCan && _isInTrashArea(size)) {
                      captainVisible = false;
                    }
                    showTrashCan = false;
                  });
                },
                onTap: () {
                  if (!isDragging) {
                    Navigator.pushNamed(context, '/chat');
                  }
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.scale(
                      scale: isDragging ? 1.1 : _pulse.value,
                      child: child,
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDragging
                                    ? Colors.black38
                                    : Colors.black26,
                                blurRadius: isDragging ? 12 : 6,
                                offset: Offset(0, isDragging ? 6 : 3),
                              ),
                            ],
                          ),
                          child: _captainBubbleImage(radius: captainRadius),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Kaptan",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDragging
                                ? AppColors.accent
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Çöp kutusu (sürüklerken göster) - sayfa altında
          if (showTrashCan && isDragging)
            Positioned(
              bottom: 64, // Bottom bar'ın üstünde
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 36,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Sil",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // ------- ALT BAR (en alta) -------
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Container(
          color: Colors.white, // Ekstra beyaz renk garantisi
          height: 64,
          child: Row(
            children: [
              // Sol blok (2 item)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomNavItem(
                      label: 'Ana Sayfa',
                      selected: _tab == 0,
                      assetPath: kIconHome,
                      fallbackIcon: Icons.home_rounded,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _BottomNavItem(
                      label: 'Başvurular',
                      selected: _tab == 1,
                      assetPath: kIconApps,
                      fallbackIcon: Icons.assignment_outlined,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ],
                ),
              ),

              // Orta boş slot (FAB çentiği)
              const SizedBox(width: 48),

              // Sağ blok (2 item)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomNavItem(
                      label: 'Para Gönder',
                      selected: _tab == 2,
                      assetPath: kIconSend,
                      fallbackIcon: Icons.send_rounded,
                      onTap: () => setState(() => _tab = 2),
                    ),
                    _BottomNavItem(
                      label: 'Ödeme Yap',
                      selected: _tab == 3,
                      assetPath: kIconPay,
                      fallbackIcon: Icons.payment_rounded,
                      onTap: () => setState(() => _tab = 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ------- ORTADAKİ KAPTAN ŞAPKASI (center docked) -------
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          // ÖNCEKİ: AppColors.accent (sarı dolgu)
          // YENİ: Beyaz zemin + altın sarısı HALKA
          backgroundColor: Colors.white,
          elevation: 8,
          shape: const CircleBorder(
            side: BorderSide(
              color: AppColors.accent, // sarı HALKA
              width: 3, // kalınlık
            ),
          ),
          onPressed: _openMenuQuickActions,
          child: CaptainMenuIcon(
            active: _captainHidden, // kaptan gizliyken peek animasyonu
            size: 32,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ------- ÜST DALGA -------
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
            // Denizci temalı dekoratif elementler
            Positioned(
                top: 36,
                left: -10,
                child: _navyBubble(70, AppColors.accent.withOpacity(.15))),
            Positioned(
                top: 20,
                right: -6,
                child: _navyBubble(46, Colors.white.withOpacity(.20))),
            Positioned(
                bottom: 18,
                right: 40,
                child: _navyBubble(28, AppColors.accent.withOpacity(.12))),
            // Çapa ikonu dekoratif
            Positioned(
              top: 80,
              right: 20,
              child: Icon(
                Icons.anchor,
                size: 24,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 30,
              child: Icon(
                Icons.sailing,
                size: 20,
                color: AppColors.accent.withOpacity(0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 54, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.menu, color: Colors.white, size: 24),
                  Row(
                    children: [
                      Icon(Icons.sailing, color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "CaptainBank",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: .2,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.notifications_none, color: Colors.white, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navyBubble(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ------- KARTLAR -------
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
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text("⚓", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Ahoy, Kaptan Team 1! 🏴‍☠️",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Bugün hangi denizleri fethedeceğiz? ⛵",
                    style: TextStyle(color: AppColors.textSub, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                greet,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionChip(Icons.send, "Para Gönder", AppColors.accent),
          _actionChip(Icons.receipt_long, "Fatura Öde", Colors.amber),
          _actionChip(Icons.qr_code, "QR İşlemleri", Colors.teal),
          _actionChip(Icons.anchor, "IBAN Paylaş", Colors.deepPurpleAccent),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) => Column(
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
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  Widget _buildFunStrip() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _funCard("🎯 Hedef: %45", "Kaptan primleriniz",
              [AppColors.accent, Colors.orange]),
          _funCard("📉 2,99", "Denizci faizi", [Colors.green, Colors.teal]),
          _funCard("📊 Notunu Gör", "Kaptan puanın hazır",
              [Colors.purple, Colors.indigo]),
          _funCard("🛡️ Güvende", "Kaptan korumasında",
              [AppColors.primary, AppColors.primary2]),
        ],
      ),
    );
  }

  Widget _funCard(String title, String sub, List<Color> gr) => Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gr),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))
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
            Text(sub,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Detay",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  // Menü sheet (kaptanı buradan gizle/göster)
  void _openMenuQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.smart_toy_outlined, color: Colors.black87),
                title: const Text('Kaptan sohbeti',
                    style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/chat');
                },
              ),
              if (captainVisible)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined,
                      color: Colors.black87),
                  title: const Text('Kaptan balonunu gizle',
                      style: TextStyle(color: Colors.black87)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => captainVisible = false);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.visibility_outlined,
                      color: Colors.black87),
                  title: const Text('Kaptan balonunu göster',
                      style: TextStyle(color: Colors.black87)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      captainVisible = true;
                      // Varsayılan pozisyona getir
                      captainX = defaultCaptainX;
                      captainY = defaultCaptainY;
                    });
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // Kaptan balonu resmi
  Widget _captainBubbleImage({required double radius}) {
    final size = radius * 2;
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      padding: const EdgeInsets.all(8),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/captain/captain.png',
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  // Çöp kutusu alanında mı kontrol et
  bool _isInTrashArea(Size size) {
    final trashCenterX = size.width / 2;
    final trashCenterY = size.height -
        140; // Çöp kutusu merkezi (bottom bar + çöp kutusu yüksekliği)
    final distance = ((captainX + captainRadius) - trashCenterX).abs() +
        ((captainY + captainRadius) - trashCenterY).abs();
    return distance < 100; // 100 pixel tolerans (daha geniş alan)
  }

  // Kaptanı ekran sınırları içinde tut
  void _clampCaptain(Size size) {
    final maxX = size.width - captainRadius * 2;
    final maxY = size.height - captainRadius * 2 - 64; // bottom bar
    if (captainX < 8) captainX = 8;
    if (captainY < 8) captainY = 8;
    if (captainX > maxX - 8) captainX = maxX - 8;
    if (captainY > maxY - 8) captainY = maxY - 8;
  }
}

// ---- Alt bar item (PNG veya IconData fallback) ----
class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black87 : Colors.grey[700];
    final bool hasPng = assetPath.isNotEmpty;

    final Widget icon = hasPng
        ? Image.asset(
            assetPath,
            width: 22,
            height: 22,
            filterQuality: FilterQuality.high,
            fit: BoxFit.contain,
          )
        : Icon(fallbackIcon, size: 22, color: color);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 22, child: Center(child: icon)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Üst dalga clipper ----
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 60);
    final c1 = Offset(size.width * 0.25, size.height);
    final p1 = Offset(size.width * 0.5, size.height - 30);
    final c2 = Offset(size.width * 0.75, size.height - 90);
    final p2 = Offset(size.width, size.height - 50);

    path
      ..quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, p2.dx, p2.dy)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
