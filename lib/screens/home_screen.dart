import 'package:flutter/material.dart';
import 'chat_screen.dart';

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
  // Asistan balonu pozisyonu ve durumu
  double assistantX = 200;
  double assistantY = 500;
  final double assistantRadius = 32; // Balon yarıçapı
  bool assistantVisible = true;

  // Çöp kutusu overlay state
  bool _showTrash = false;
  bool _overTrash = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenW = size.width;
    final double screenH = size.height;

    // Çöp kutusu alanı (ekran alt-orta)
    final double trashSize = 86;
    final Rect trashRect = Rect.fromCenter(
      center: Offset(screenW / 2, screenH - 40 - trashSize / 2),
      width: trashSize,
      height: trashSize,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Üst Mavi Alan
          _buildHeader(screenH),

          // Alt içerik
          Padding(
            padding: EdgeInsets.only(top: screenH * 0.28),
            child: Column(
              children: [
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildPromoCard(),
                const Spacer(),
                _buildBottomBar(onMenuTap: _openMenuQuickActions),
              ],
            ),
          ),

          // Dijital Asistan (sürüklenebilir) — PNG içerik TAM SIĞAR
          if (assistantVisible)
            Positioned(
              left: assistantX,
              top: assistantY,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _showTrash = true),
                onPanUpdate: (details) {
                  setState(() {
                    assistantX += details.delta.dx;
                    assistantY += details.delta.dy;
                    _clampAssistant(size);
                    // Asistan merkez noktası çöp alanında mı?
                    final Offset center = Offset(assistantX + assistantRadius,
                        assistantY + assistantRadius);
                    _overTrash = trashRect.contains(center);
                  });
                },
                onPanEnd: (_) {
                  if (_overTrash) {
                    setState(() {
                      assistantVisible = false;
                      _showTrash = false;
                      _overTrash = false;
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
                    });
                  }
                },
                onTap: () => Navigator.pushNamed(context, '/chat'),
                child: Column(
                  children: [
                    // Gölge + dairesel çerçeve + İMAGE CONTAIN
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
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
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
                    size: 34,
                    color: _overTrash ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
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
      padding: const EdgeInsets.all(10), // kenarlara değmesin
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/chatbot/kalpli.png',
          fit: BoxFit.contain, // 🔹 TAM SIĞDIR
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  // Üst mavi kart
  Widget _buildHeader(double screenH) {
    return Container(
      height: screenH * 0.35,
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
        children: const [
          // Üst Menü
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.menu, color: Colors.white),
              Text(
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
          SizedBox(height: 20),
          // Hesap Bilgisi
          Text(
            "00000001 - 351 / Intertech Kurtköy",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "Kullanılabilir Bakiye",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            "0,00 TL",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  // Hızlı işlem butonları
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(Icons.send, "Para Gönder"),
          _actionButton(Icons.receipt_long, "Fatura Öde"),
          _actionButton(Icons.qr_code, "QR İşlemleri"),
          _actionButton(Icons.share, "IBAN Paylaş"),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 24,
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Reklam kartı
  Widget _buildPromoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const ListTile(
          leading: Icon(Icons.security, color: AppColors.primary),
          title: Text(
            "Acil Güvence FKS ile Risklere Karşı Hazırlıklı Olun!",
            style: TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            "Güvence Altına Alın",
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  // Alt bar – Menü item’ı asistan kısa yolu içerir
  Widget _buildBottomBar({required VoidCallback onMenuTap}) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.home, label: "Ana Sayfa", onTap: () {}),
          _BottomNavItem(
              icon: Icons.assignment, label: "Başvurular", onTap: () {}),
          _BottomNavItem(
              icon: Icons.settings, label: "Menü", onTap: onMenuTap), // Kısayol
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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

  // Asistanı ekran sınırları içinde tut
  void _clampAssistant(Size size) {
    final double maxX = size.width - assistantRadius * 2;
    final double maxY = size.height -
        assistantRadius * 2 -
        60; // alt bar yüksekliği kadar boşluk
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
