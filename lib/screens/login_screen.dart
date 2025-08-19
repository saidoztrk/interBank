import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankStyleLoginScreen extends StatefulWidget {
  const BankStyleLoginScreen({super.key});

  @override
  State<BankStyleLoginScreen> createState() => _BankStyleLoginScreenState();
}

class _BankStyleLoginScreenState extends State<BankStyleLoginScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  // Kullanıcı geçişi
  final List<String> _users = ["Team 1", "Team 2", "Team 3"];
  int _selectedUser = 0;

  String get currentUserName => _users[_selectedUser];
  final String _segment = "Bireysel";

  void _onLoginPressed() => _showPinSheet();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Arka plan görseli üstüne yumuşak mavi bir overlay (okunabilirlik için)
    const overlayGradient = LinearGradient(
      colors: [
        Color(0xAA0C5DB1), // üst: yoğun mavi, yarı saydam
        Color(0x660870C9), // alt: daha şeffaf mavi
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Deniz arka planı
            Image.asset(
              'lib/assets/images/captain/login/Sea-Background.jpeg',
              fit: BoxFit.cover,
            ),

            // 2) Okunabilirlik için yarı saydam mavi gradyan overlay
            const DecoratedBox(
              decoration: BoxDecoration(gradient: overlayGradient),
            ),

            // 3) İçerik
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    "CaptainCep",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Üst kısayollar
                  SizedBox(
                    height: 76,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _TopShortcut(icon: Icons.verified_user, label: "Güvenlik"),
                        _TopShortcut(icon: Icons.account_balance_wallet, label: "Yatırım"),
                        _TopShortcut(icon: Icons.local_offer, label: "Pazarama"),
                        _TopShortcut(icon: Icons.business_center, label: "Genç KOBİ"),
                        _TopShortcut(icon: Icons.apps, label: "Daha Fazla"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _pageIndex = i),
                            children: [
                              // 0: Var olan kullanıcı (PIN ile)
                              _ExistingUserCard(
                                name: currentUserName,
                                segment: _segment,
                                onLogin: _onLoginPressed,
                                users: _users,
                                selectedUserIndex: _selectedUser,
                                onPickUser: (i) => setState(() => _selectedUser = i),
                              ),

                              // 1: Yeni kullanıcı
                              _NewUserCard(
                                onBireysel: _showNewUserLoginSheet,
                                onTicari: _showCommercialLoginSheet,
                              ),
                            ],
                          ),
                        ),

                        // Page indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            2,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _pageIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),

                        _BottomCardsAndShortcuts(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PIN Bottom Sheet ---
  void _showPinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String pin = "";
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void addDigit(String d) {
              if (pin.length >= 6) return;
              setSheetState(() => pin += d);
              if (pin.length == 6) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (pin == "123456") {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Şifre hatalı. Tekrar deneyin."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setSheetState(() => pin = "");
                  }
                });
              }
            }

            void removeDigit() {
              if (pin.isEmpty) return;
              setSheetState(() => pin = pin.substring(0, pin.length - 1));
            }

            return Container(
              padding: EdgeInsets.only(
                left: 18, right: 18, top: 12,
                bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12, borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Şifre • $currentUserName",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < pin.length ? const Color(0xFF0C5DB1) : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _NumberPad(
                    onDigit: addDigit,
                    onBackspace: removeDigit,
                    onClose: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Yeni kullanıcı (Bireysel) formu ---
  void _showNewUserLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final tc = TextEditingController();
        final pw = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return Container(
          padding: EdgeInsets.only(
            left: 18, right: 18, top: 12,
            bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  "Bireysel Giriş",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: tc,
                  keyboardType: TextInputType.number,
                  decoration: _filledDecoration(
                    label: "Müşteri / T.C. No",
                    icon: Icons.badge_outlined,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pw,
                  obscureText: true,
                  decoration: _filledDecoration(
                    label: "Şifre",
                    icon: Icons.lock_outline,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 16),

                _primaryAction(
                  label: "GİRİŞ",
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (tc.text.trim() == "100200300" && pw.text.trim() == "123456") {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        _errorSnack("Bilgiler hatalı. Tekrar deneyin.");
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text("ŞİFRE OLUŞTUR / UNUTTUM"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Yeni kullanıcı (Ticari) formu ---
  void _showCommercialLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final vkn = TextEditingController();
        final user = TextEditingController();
        final pw = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return Container(
          padding: EdgeInsets.only(
            left: 18, right: 18, top: 12,
            bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  "Ticari Giriş",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: vkn,
                  keyboardType: TextInputType.number,
                  decoration: _filledDecoration(
                    label: "VKN / Firma No",
                    icon: Icons.apartment_outlined,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: user,
                  decoration: _filledDecoration(
                    label: "Kullanıcı Kodu",
                    icon: Icons.badge,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pw,
                  obscureText: true,
                  decoration: _filledDecoration(
                    label: "Şifre",
                    icon: Icons.lock_outline,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 16),

                _primaryAction(
                  label: "GİRİŞ",
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (vkn.text.trim() == "1112223334" &&
                          user.text.trim() == "team" &&
                          pw.text.trim() == "654321") {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        _errorSnack("Bilgiler hatalı. Tekrar deneyin.");
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text("ŞİFRE OLUŞTUR / UNUTTUM"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----- Helpers -----
  InputDecoration _filledDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF6F9FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? "Zorunlu alan" : null;

  Widget _primaryAction({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C5DB1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _errorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Widget _sheetHandle() => Center(
        child: Container(
          width: 44, height: 5,
          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
        ),
      );
}

// ---------- Widgets ----------

class _TopShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TopShortcut({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ExistingUserCard extends StatelessWidget {
  final String name;
  final String segment;
  final VoidCallback onLogin;

  // kullanıcı seçimi
  final List<String> users;
  final int selectedUserIndex;
  final ValueChanged<int> onPickUser;

  const _ExistingUserCard({
    required this.name,
    required this.segment,
    required this.onLogin,
    required this.users,
    required this.selectedUserIndex,
    required this.onPickUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.white,
          child: const CircleAvatar(
            radius: 43,
            backgroundImage: AssetImage('lib/assets/images/person/teamwork.png'),
          ),
        ),
        const SizedBox(height: 14),

        // İsim + segment + kullanıcı geçiş menüsü
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<int>(
                iconSize: 18,
                color: Colors.white,
                elevation: 6,
                offset: const Offset(0, 24),
                onSelected: onPickUser,
                itemBuilder: (context) => [
                  for (int i = 0; i < users.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          if (i == selectedUserIndex) const Icon(Icons.check, size: 18),
                          if (i == selectedUserIndex) const SizedBox(width: 6),
                          Text(users[i]),
                        ],
                      ),
                    ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          segment,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 22),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BC6FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("GİRİŞ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        TextButton(
          onPressed: () {},
          child: Text(
            "YENİ ŞİFRE AL",
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewUserCard extends StatelessWidget {
  final VoidCallback onBireysel;
  final VoidCallback onTicari;
  const _NewUserCard({required this.onBireysel, required this.onTicari});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        const CircleAvatar(
          radius: 46,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 42, color: Color(0xFF0C5DB1)),
        ),
        const SizedBox(height: 14),
        const Text(
          "Yeni Kullanıcı",
          style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Farklı bir kullanıcı ile oturum açın",
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
        ),
        const SizedBox(height: 22),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(child: _PrimaryButton(label: "BİREYSEL", onPressed: onBireysel)),
              const SizedBox(width: 12),
              Expanded(child: _PrimaryButton(label: "TİCARİ", onPressed: onTicari)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () {},
          child: Text(
            "ŞİFRE OLUŞTUR",
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0C5DB1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BottomCardsAndShortcuts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Expanded(child: _InfoCard(title: "Mobil Borsa", icon: Icons.bar_chart)),
              SizedBox(width: 12),
              Expanded(child: _InfoCard(title: "Kampanyalar", icon: Icons.campaign)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _QuickTile(icon: Icons.flash_on, label: "FAST\nİşlemleri"),
              _QuickTile(icon: Icons.stacked_line_chart, label: "Fiyat ve\nOranlar"),
              _QuickTile(icon: Icons.qr_code_2, label: "Karekod\nİşlemleri"),
              _QuickTile(icon: Icons.more_horiz, label: "Daha\nFazlası"),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 120, height: 5,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const _InfoCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0C5DB1)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0C5DB1), size: 28),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _NumberPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClose;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'close','0','back',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.4,
      ),
      padding: const EdgeInsets.only(bottom: 10),
      itemBuilder: (_, i) {
        final k = keys[i];
        if (k == 'close') {
          return _PadButton(
            child: const Text("KAPAT", style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: onClose,
          );
        }
        if (k == 'back') {
          return _PadButton(
            child: const Icon(Icons.backspace_outlined),
            onTap: onBackspace,
          );
        }
        return _PadButton(
          child: Text(k, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          onTap: () => onDigit(k),
        );
      },
    );
  }
}

class _PadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PadButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}
