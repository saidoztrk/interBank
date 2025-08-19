// lib/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart'; // BankStyleLoginScreen burada

class AppColors {
  static const background = Color(0xFF0A1628);
  static const primary    = Color(0xFF1E3A8A); // lacivert
  static const primary2   = Color(0xFF3B82F6); // açık mavi
  static const accent     = Color(0xFFFFD700);
  static const textLight  = Color(0xFFE5E7EB);
  static const textSub    = Color(0xFFD1D5DB);
  static const cardBg     = Color(0xFF1F2937);
  static const bar        = Colors.white;
}

// Alt bar PNG ikonları
const String kIconHome    = 'lib/assets/images/captain/home/home.png';
const String kIconApps    = 'lib/assets/images/captain/home/apps.png';
const String kIconSend    = 'lib/assets/images/captain/home/send.png';
const String kIconPay     = 'lib/assets/images/captain/home/pay.png';
const String kIconCaptain = 'lib/assets/images/captain/captain.png';

// Bottom nav yüksekliği (scroll alt boşluğu için de kullanılıyor)
const double kNavHeight = 140.0;

// ---- Hesap modeli (login/LLM sonrası doldurulacak) ----
class AccountInfo {
  final String musteriNo;
  final String adSoyad;
  final String bakiye; // formatlı string (örn. 23.540,75 ₺)
  const AccountInfo({required this.musteriNo, required this.adSoyad, required this.bakiye});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  AccountInfo? _account;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _loadAccountMock(); // TODO: login tamamlanınca kendi servisinle değiştir
  }

  // PNG'leri önceden cache'leyelim (ilk frame "takılmasın")
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in [kIconHome, kIconApps, kIconSend, kIconPay, kIconCaptain]) {
      precacheImage(AssetImage(a), context);
    }
  }

  Future<void> _loadAccountMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    setState(() {
      _account = const AccountInfo(
        musteriNo: "12345678",
        adSoyad: "Erenay Çevik",
        bakiye: "23.540,75 ₺",
      );
    });
  }

  Future<void> _performLogout() async {
    // TODO: token/refresh temizliği, local state reset, vs.
    // Örn: await secureStorage.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // İçerik üst boşluğu — senin talebinle:
    final double contentTop = math.max(100, size.height * 0.15);

    return Scaffold(
      backgroundColor: AppColors.background,

      // ------- GÖVDE -------
      body: Stack(
        children: [
          _buildWavyHeader(context),

          // İçerikler
          Padding(
            padding: EdgeInsets.only(top: contentTop),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: kNavHeight + MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                children: [
                  _buildAccountCard(_account), // büyütülmüş — bakiye altta + göz ikonu
                  const SizedBox(height: 16),
                  _buildGreetingCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 10),
                  _buildFunStrip(),
                ],
              ),
            ),
          ),
        ],
      ),

      // ------- CUSTOM NAVBAR (yüksek, ripple YOK, PNG bozulmaz) -------
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: SizedBox(
          height: kNavHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Beyaz arka panel
              Positioned.fill(
                top: 48,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -2)),
                    ],
                  ),
                  // Dört butonu hafif sola kaydır
                  padding: const EdgeInsets.fromLTRB(12, 0, 28, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navIcon(kIconHome, 'Ana Sayfa', _tab == 0, () => setState(() => _tab = 0)),
                      _navIcon(kIconApps, 'Başvurular', _tab == 1, () => setState(() => _tab = 1)),
                      const SizedBox(width: 88), // merkez buton boşluğu
                      _navIcon(kIconSend, 'Para Gönder', _tab == 2, () => setState(() => _tab = 2)),
                      _navIcon(kIconPay, 'Ödeme Yap', _tab == 3, () => setState(() => _tab = 3)),
                    ],
                  ),
                ),
              ),

              // 🔵 Ortadaki kaptan çemberi + “Kaptan”
              Positioned(
                top: -6,
                child: Transform.translate(
                  offset: const Offset(-12, 0), // az sola
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pushNamed(context, '/chat');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 86, height: 86,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary2],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
                              BoxShadow(color: Color(0x553B82F6), blurRadius: 30, spreadRadius: -8, offset: Offset(0, 10)),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(kIconCaptain, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kaptan',
                        style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 36, left: -10, child: _navyBubble(70, AppColors.accent.withOpacity(.15))),
            Positioned(top: 20, right: -6, child: _navyBubble(46, Colors.white.withOpacity(.20))),
            Positioned(bottom: 18, right: 40, child: _navyBubble(28, AppColors.accent.withOpacity(.12))),
            Positioned(top: 80, right: 20, child: Icon(Icons.anchor, size: 24, color: Colors.white.withOpacity(0.3))),
            Positioned(bottom: 40, left: 30, child: Icon(Icons.sailing, size: 20, color: AppColors.accent.withOpacity(0.4))),
            Padding(
              padding: const EdgeInsets.only(top: 54, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, color: Colors.white, size: 24),
                  const Row(
                    children: [
                      Icon(Icons.sailing, color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text("CaptainBank",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: .2)),
                    ],
                  ),
                  _buildLogoutButton(context), // 🔴 Zil yerine Çıkış butonu
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 Sağ üst KIRMIZI ÇIKIŞ butonu — doğrudan BankStyleLoginScreen'e gider, stack'i temizler
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ripple YOK
      onTap: () async {
        HapticFeedback.selectionClick();
        await _performLogout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const BankStyleLoginScreen(), // ✅ doğru sınıf adı
            settings: const RouteSettings(name: 'login'),
          ),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48), // kırmızı
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              "Çıkış",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------- HESAP KARTI (büyütülmüş, bakiye altta, gizle-göster) -------
  Widget _buildAccountCard(AccountInfo? acc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.35), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: avatar + isim + müşteri no + göz
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(.2), shape: BoxShape.circle),
                  child: const Icon(Icons.account_circle, color: AppColors.accent, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc?.adSoyad ?? "— —",
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text("Müşteri No: ${acc?.musteriNo ?? "— —"}",
                          style: const TextStyle(color: AppColors.textSub, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _hideBalance = !_hideBalance),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    _hideBalance ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(.85),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Alt: Bakiye bandı (tam genişlik)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bakiye",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: .2)),
                  const SizedBox(height: 4),
                  Text(
                    _hideBalance ? "•••••• ₺" : (acc?.bakiye ?? "— ₺"),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navyBubble(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  // ------- KARTLAR / STRIP -------
  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? "Günaydın" : hour < 18 ? "İyi günler" : "İyi akşamlar";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.20), width: 1), // bir tık sönük
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), shape: BoxShape.circle),
              child: const Text("⚓", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ahoy, Kaptan Team 1! 🏴‍☠️",
                      style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text("Bugün hangi denizleri fethedeceğiz? ⛵",
                      style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(.25), borderRadius: BorderRadius.circular(999)),
              child: Text(greet, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600)),
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
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildFunStrip() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _funCard("🎯 Hedef: %45", "Kaptan primleriniz", [AppColors.accent, Colors.orange]),
          _funCard("📉 2,99", "Denizci faizi", [Color(0xFF10B981), Color(0xFF059669)]),
          _funCard("📊 Notunu Gör", "Kaptan puanın hazır", [Colors.purple, Colors.indigo]),
          _funCard("🛡️ Güvende", "Kaptan korumasında", [AppColors.primary, AppColors.primary2]),
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
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
              child: const Text("Detay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ---- navbar ikon helper (ripple yok, tint yok, haptic var) ----
  Widget _navIcon(String asset, String label, bool selected, VoidCallback onTap) {
    final BoxDecoration bg = selected
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary2],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
              BoxShadow(color: Color(0x553B82F6), blurRadius: 28, spreadRadius: -8, offset: Offset(0, 10)),
            ],
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0x11000000)),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 6))],
          );

    // PNG'lere tint yok
    final Widget iconImg = Image.asset(
      asset, width: 24, height: 24, fit: BoxFit.contain, filterQuality: FilterQuality.high,
    );

    final Color labelColor = selected ? AppColors.primary : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 48, height: 48,
              decoration: bg,
              child: Center(child: iconImg),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
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
