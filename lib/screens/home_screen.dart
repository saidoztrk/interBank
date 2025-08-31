// lib/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../services/session_manager.dart';
import '../providers/db_provider.dart';
import '../models/customer.dart';
import '../models/account.dart';

import 'login_screen.dart';

class AppColors {
  static const background = Color(0xFF0A1628);
  static const primary    = Color(0xFF1E3A8A);
  static const primary2   = Color(0xFF3B82F6);
  static const accent     = Color(0xFFFFD700);
  static const textLight  = Color(0xFFE5E7EB);
  static const textSub    = Color(0xFFD1D5DB);
  static const cardBg     = Color(0xFF1F2937);
  static const bar        = Colors.white;
}

const String kIconHome    = 'lib/assets/images/captain/home/home.png';
const String kIconApps    = 'lib/assets/images/captain/home/apps.png';
const String kIconSend    = 'lib/assets/images/captain/home/send.png';
const String kIconPay     = 'lib/assets/images/captain/home/pay.png';
const String kIconCaptain = 'lib/assets/images/captain/captain.png';

const double kNavHeight = 140.0;

class AccountInfo {
  final String musteriNo;
  final String adSoyad;
  final String bakiye;
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

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in [kIconHome, kIconApps, kIconSend, kIconPay, kIconCaptain]) {
      precacheImage(AssetImage(a), context);
    }
  }

  String _formatTry(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    String intPart = parts[0];
    final decPart = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final rev = intPart.length - 1 - i;
      buf.write(intPart[i]);
      if (rev % 3 == 0 && i != intPart.length - 1) buf.write('.');
    }
    return '${buf.toString()},$decPart ₺';
  }

  double? _selectBalance(List<Account> list) {
    try {
      final pri = list.firstWhere((a) {
        final cur = a.currency.toUpperCase();
        final t = a.type.toLowerCase();
        return cur == 'TRY' && (t.contains('vadesiz') || t == 'checking' || t == 'deposit');
      });
      return pri.balance;
    } catch (_) {
      final total = list
          .where((a) => a.currency.toUpperCase() == 'TRY')
          .fold<double>(0.0, (sum, a) => sum + a.balance);
      return total == 0.0 ? null : total;
    }
  }

  Future<void> _loadAccountData() async {
    debugPrint('[Home][Init] loadAccountData start');
    setState(() { _loading = true; _error = null; });

    try {
      final cNo = SessionManager.customerNo;
      if (cNo == null) {
        throw Exception('Oturumda customerNo yok. Login sonrası SessionManager.saveCustomerNo çağrılmalı.');
      }

      final dbp = context.read<DbProvider>();

      // 🔧 ÖNEMLİ: Cache müşteri ID’si, oturumdaki ID ile aynı değilse mutlaka yeniden yükle
      if (dbp.customer == null || dbp.customer!.customerId != cNo) {
        debugPrint('[Home][API] loadCustomerById($cNo) (cache miss or different user)');
        await dbp.loadCustomerById(cNo);
      } else {
        debugPrint('[Home][API] customer cached: ${dbp.customer!.fullName} (#${dbp.customer!.customerId})');
      }
      final Customer? cust = dbp.customer;

      debugPrint('[Home][API] getAccountsByCustomer($cNo)');
      final accounts = await dbp.api.getAccountsByCustomer(cNo.toString());
      debugPrint('[Home][API] accounts fetched: ${accounts.length}');
      final bal = _selectBalance(accounts);
      final formattedBal = (bal != null) ? _formatTry(bal) : '— ₺';

      // İsim: öncelik API’den gelen customer.fullName
      String name = cust?.fullName ?? '';
      if (name.isEmpty) {
        name = SessionManager.username ?? '';
      }
      if (name.isEmpty) {
        name = await SessionManager.getLastFullName() ?? '— —';
      }

      if (!mounted) return;
      setState(() {
        _account = AccountInfo(
          musteriNo: cNo.toString(),
          adSoyad: name,
          bakiye: formattedBal,
        );
      });

      debugPrint('[Home][Init] ok name=$name custNo=$cNo balance=$formattedBal');
    } catch (e, st) {
      debugPrint('[Home][Error] $e\n$st');
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  Future<void> _performLogout() async {
    // Örn: await SessionManager.clearAuthOnly();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double contentTop = math.max(100, size.height * 0.15);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildWavyHeader(context),
          Padding(
            padding: EdgeInsets.only(top: contentTop),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? _errorView(_error!)
                    : SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: kNavHeight + MediaQuery.of(context).padding.bottom + 24,
                        ),
                        child: Column(
                          children: [
                            _buildAccountCard(_account),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 28, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navIcon(kIconHome, 'Ana Sayfa', _tab == 0, () => setState(() => _tab = 0)),
                      _navIcon(kIconApps, 'Başvurular', _tab == 1, () => setState(() => _tab = 1)),
                      const SizedBox(width: 88),
                      _navIcon(kIconSend, 'Para Gönder', _tab == 2, () => setState(() => _tab = 2)),
                      _navIcon(kIconPay, 'Ödeme Yap', _tab == 3, () => setState(() => _tab = 3)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -6,
                child: Transform.translate(
                  offset: const Offset(-12, 0),
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

  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text('Bir şeyler ters gitti',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(msg, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAccountData, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );

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
                      Text(
                        "CaptainBank",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: .2),
                      ),
                    ],
                  ),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        HapticFeedback.selectionClick();
        await _performLogout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const BankStyleLoginScreen(),
            settings: const RouteSettings(name: 'login'),
          ),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text("Çıkış",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .2)),
          ],
        ),
      ),
    );
  }

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
          border: Border.all(color: AppColors.accent.withOpacity(0.20), width: 1),
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
              decoration:
                  BoxDecoration(color: AppColors.accent.withOpacity(.25), borderRadius: BorderRadius.circular(999)),
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

    final Widget iconImg =
        Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain, filterQuality: FilterQuality.high);

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
              width: 48,
              height: 48,
              decoration: bg,
              child: Center(child: iconImg),
            ),
            const SizedBox(height: 8),
            Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor)),
          ],
        ),
      ),
    );
  }
}

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
