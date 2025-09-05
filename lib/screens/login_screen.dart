// lib/screens/login_screen.dart
// -----------------------------------------------------------
// Erenay tarafından güncellendi:
// - "Yeni Bireysel" sheet'i ayrı StatefulWidget'a taşındı (fokus/jump fix)
// - Controller/FocusNode tek kez oluşturuluyor; klavye açılıp kapanınca
//   T.C. alanına geri zıplama sorunu bitti.
// - İlk alana autofocus sadece bir kez veriliyor (initState).
// - Parola alanı TextInputAction.done + buildCounter gizli.
// - Gerçek Azure DB API login akışı korunuyor, loglar eklendi.
// - Claude tarafından responsive tasarım eklendi
// - SnackBar klavyenin üstünde görünecek şekilde düzenlendi
// -----------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/session_manager.dart';
import '../providers/db_provider.dart'; // api örneğine ulaşmak için

class BankStyleLoginScreen extends StatefulWidget {
  const BankStyleLoginScreen({super.key});

  @override
  State<BankStyleLoginScreen> createState() => _BankStyleLoginScreenState();
}

class _BankStyleLoginScreenState extends State<BankStyleLoginScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  String? _lastUsername;
  String? _lastFullName;

  @override
  void initState() {
    super.initState();
    _loadLastUser();
  }

  Future<void> _loadLastUser() async {
    final u = await SessionManager.getLastUsername();
    final n = await SessionManager.getLastFullName();
    // ignore: avoid_print
    print('[Erenay][LOGIN] last user: u=$u, name=$n');
    if (mounted) {
      setState(() {
        _lastUsername = u;
        _lastFullName = n;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- PIN Bottom Sheet (Son kullanıcı için) ---
  void _showPinSheet() {
    if (_lastUsername == null || _lastUsername!.isEmpty) {
      _errorSnack(
          'Kayıtlı kullanıcı bulunamadı. Önce "Yeni Kullanıcı" ile giriş yapın.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String pin = "";
        bool showError = false; // Hata durumu için state

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> tryLogin() async {
              if (pin.length != 6) return;
              // ignore: avoid_print
              print('[Erenay][PIN] try login | lastUsername=$_lastUsername');

              try {
                final db = context.read<DbProvider>().api; // ApiDbManager
                final result = await db.loginDb(
                  username: _lastUsername!,
                  password: pin,
                );

                // ignore: avoid_print
                print(
                    '[Erenay][PIN] login success | cid=${result.customerId} name=${result.fullName}');

                await SessionManager.saveLastUsername(_lastUsername!);
                if (result.fullName.isNotEmpty) {
                  await SessionManager.saveLastFullName(result.fullName);
                }

                if (!mounted) return;
                Navigator.of(context).pop(); // sheet kapat
                Navigator.pushReplacementNamed(context, '/home');
              }  catch (e) {
  // ignore: avoid_print
  print('[Erenay][PIN] login FAIL: $e');
  HapticFeedback.mediumImpact();
  
  // ESKİ KODLARI SİL, BUNLARI EKLE:
  setSheetState(() {
    pin = "";
    showError = true;
  });
  
  // 3 saniye sonra hata mesajını gizle
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      setSheetState(() {
        showError = false;
      });
    }
  });
              }
            }

            void addDigit(String d) {
               if (pin.length >= 6) return;
  setSheetState(() {
    pin += d;
    // BU SATIRI EKLE:
    if (showError) showError = false; // Hata mesajını gizle
  });
  if (pin.length == 6) {
    Future.delayed(const Duration(milliseconds: 120), tryLogin);
  }
            }

            void removeDigit() {
               if (pin.isEmpty) return;
  setSheetState(() {
    pin = pin.substring(0, pin.length - 1);
    // BU SATIRI EKLE:
    if (showError) showError = false; // Hata mesajını gizle
  });
            }

             return Container(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 12,
              bottom: 18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                
                // HATA MESAJI KUTUSU - EN ÜST KISIMDAE
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: showError ? 50 : 0,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: showError
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Şifre hatalı. Tekrar deneyin.",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                
                Text(
                  "Şifre • ${_lastFullName ?? _lastUsername ?? ''}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < pin.length
                            ? (showError ? Colors.red : const Color(0xFF0C5DB1))
                            : Colors.black12,
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

  // --- Yeni kullanıcı (Bireysel) formu – ayrı widget'a taşındı ---
  void _showNewUserLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BireyselLoginSheet(
        onSuccess: () async {
          await _loadLastUser(); // başlıktaki ismi güncelle
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        },
      ),
    );
  }

  // --- Yeni kullanıcı (Ticari) formu (şimdilik pasif tutuyoruz) ---
  void _showCommercialLoginSheet() {
    _errorSnack('Ticari giriş bu sürümde kapalı. Lütfen Bireysel ile deneyin.');
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Responsive değerler
    final titleFontSize = screenWidth * 0.055; // ~22 normal ekranlarda
    final shortcutHeight = screenHeight * 0.095; // ~76 normal ekranlarda
    final avatarRadius = screenWidth * 0.115; // ~46 normal ekranlarda
    
    const overlayGradient = LinearGradient(
      colors: [Color(0xAA0C5DB1), Color(0x660870C9)],
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
            Image.asset(
              'lib/assets/images/captain/login/Sea-Background.jpeg',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
                decoration: BoxDecoration(gradient: overlayGradient)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.008), // ~6
                          Text(
                            "CaptainCep",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: screenHeight * 0.012), // ~10

                          // üst kısayollar (responsive)
                          SizedBox(
                            height: shortcutHeight,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              scrollDirection: Axis.horizontal,
                              children: [
                                _TopShortcut(
                                    icon: Icons.verified_user, 
                                    label: "Güvenlik",
                                    screenWidth: screenWidth),
                                _TopShortcut(
                                    icon: Icons.account_balance_wallet,
                                    label: "Yatırım",
                                    screenWidth: screenWidth),
                                _TopShortcut(
                                    icon: Icons.local_offer, 
                                    label: "Pazarama",
                                    screenWidth: screenWidth),
                                _TopShortcut(
                                    icon: Icons.business_center, 
                                    label: "Genç KOBİ",
                                    screenWidth: screenWidth),
                                _TopShortcut(
                                    icon: Icons.apps, 
                                    label: "Daha Fazla",
                                    screenWidth: screenWidth),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.008), // ~6

                          // Ana içerik alanı
                          SizedBox(
                            height: constraints.maxHeight - 
                                    (shortcutHeight + titleFontSize + screenHeight * 0.028),
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (i) =>
                                        setState(() => _pageIndex = i),
                                    children: [
                                      // 0: Son kullanıcı (PIN ile)
                                      _ExistingUserCard(
                                        fullName: _lastFullName ??
                                            _lastUsername ??
                                            'Kayıtlı Kullanıcı Yok',
                                        onLogin: _showPinSheet,
                                        hasUser: _lastUsername != null,
                                        avatarRadius: avatarRadius,
                                        screenHeight: screenHeight,
                                        screenWidth: screenWidth,
                                      ),

                                      // 1: Yeni kullanıcı
                                      _NewUserCard(
                                        onBireysel: _showNewUserLoginSheet,
                                        onTicari: _showCommercialLoginSheet,
                                        avatarRadius: avatarRadius,
                                        screenHeight: screenHeight,
                                        screenWidth: screenWidth,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Sayfa göstergeleri
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.01),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      2,
                                      (i) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
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
                                ),
                                
                                _BottomCardsAndShortcuts(
                                  screenHeight: screenHeight,
                                  screenWidth: screenWidth,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Helpers -----

  void _errorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          left: 10,
          right: 10,
        ),
      ),
    );
  }
}

// ====== Bireysel Sheet (AYRI STATEFUL WIDGET) ======

class _BireyselLoginSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _BireyselLoginSheet({required this.onSuccess});

  @override
  State<_BireyselLoginSheet> createState() => _BireyselLoginSheetState();
}

class _BireyselLoginSheetState extends State<_BireyselLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userCtrl;
  late final TextEditingController _pwCtrl;
  late final FocusNode _userFocus;
  late final FocusNode _pwFocus;
  bool _didAutofocus = false;
  bool _showError = false; // Hata state'i ekle
  String _errorMessage = ""; // Hata mesajı

  @override
  void initState() {
    super.initState();
    _userCtrl = TextEditingController();
    _pwCtrl = TextEditingController();
    _userFocus = FocusNode();
    _pwFocus = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didAutofocus) {
        _userFocus.requestFocus();
        _didAutofocus = true;
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _pwCtrl.dispose();
    _userFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _userCtrl.text.trim();
    final password = _pwCtrl.text.trim();

    // ignore: avoid_print
    print('[Erenay][BIREYSEL] try login | u=$username');

    try {
      final db = context.read<DbProvider>().api;
      final result = await db.loginDb(username: username, password: password);

      // ignore: avoid_print
      print(
          '[Erenay][BIREYSEL] login success | cid=${result.customerId} name=${result.fullName}');

      await SessionManager.saveLastUsername(username);
      if (result.fullName.isNotEmpty) {
        await SessionManager.saveLastFullName(result.fullName);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      // ignore: avoid_print
      print('[Erenay][BIREYSEL] login FAIL: $e');
      
      // Hata mesajını göster
      setState(() {
        _showError = true;
        _errorMessage = 'Bilgiler hatalı. Tekrar deneyin.';
      });
      
      // 3 saniye sonra gizle
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showError = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            
            // HATA MESAJI KUTUSU
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showError ? 50 : 0,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _showError
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            Text(
              "Bireysel Giriş",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w700
              ),
            ),
            const SizedBox(height: 16),

            // Form alanları...
            TextFormField(
              controller: _userCtrl,
              focusNode: _userFocus,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              onChanged: (_) {
                // Kullanıcı yazmaya başladığında hata mesajını gizle
                if (_showError) {
                  setState(() {
                    _showError = false;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: "Müşteri No / T.C. / E-posta",
                prefixIcon: Icon(Icons.badge_outlined),
                filled: true,
                fillColor: Color(0xFFF6F9FF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14))),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Zorunlu alan" : null,
              onFieldSubmitted: (_) => _pwFocus.requestFocus(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _pwCtrl,
              focusNode: _pwFocus,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                // Kullanıcı yazmaya başladığında hata mesajını gizle
                if (_showError) {
                  setState(() {
                    _showError = false;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: "6 haneli şifre",
                prefixIcon: Icon(Icons.lock_outline),
                filled: true,
                fillColor: Color(0xFFF6F9FF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14))),
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Zorunlu alan" : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 6),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C5DB1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  "GİRİŞ",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w700
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: Text(
                "ŞİFRE OLUŞTUR / UNUTTUM",
                style: TextStyle(fontSize: screenWidth * 0.034),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Küçük görsel bileşenler (responsive düzenlendi) ----------

class _TopShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final double screenWidth;
  
  const _TopShortcut({
    required this.icon, 
    required this.label, 
    required this.screenWidth
  });

  @override
  Widget build(BuildContext context) {
    final containerWidth = screenWidth * 0.21; // ~84
    final iconSize = screenWidth * 0.065; // ~26
    
    return Container(
      width: containerWidth,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: containerWidth * 0.62, // ~52
            height: containerWidth * 0.62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, 
              fontSize: screenWidth * 0.03 // ~12
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingUserCard extends StatelessWidget {
  final String fullName;
  final VoidCallback onLogin;
  final bool hasUser;
  final double avatarRadius;
  final double screenHeight;
  final double screenWidth;
  
  const _ExistingUserCard({
    required this.fullName,
    required this.onLogin,
    required this.hasUser,
    required this.avatarRadius,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.022), // ~18
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: avatarRadius - 3,
              backgroundImage:
                  const AssetImage('lib/assets/images/person/teamwork.png'),
            ),
          ),
          SizedBox(height: screenHeight * 0.017), // ~14
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.05, // ~20
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.005), // ~4
          Text(
            "Bireysel",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9), 
              fontSize: screenWidth * 0.04 // ~16
            ),
          ),
          SizedBox(height: screenHeight * 0.027), // ~22
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: SizedBox(
              width: double.infinity,
              height: screenHeight * 0.067, // ~54
              child: ElevatedButton(
                onPressed: hasUser ? onLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasUser ? const Color(0xFF7BC6FF) : Colors.white24,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  "GİRİŞ",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // ~18
                    fontWeight: FontWeight.w700
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.017), // ~14
          TextButton(
            onPressed: () {},
            child: Text(
              "YENİ ŞİFRE AL",
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
                fontSize: screenWidth * 0.035, // ~14
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewUserCard extends StatelessWidget {
  final VoidCallback onBireysel;
  final VoidCallback onTicari;
  final double avatarRadius;
  final double screenHeight;
  final double screenWidth;
  
  const _NewUserCard({
    required this.onBireysel,
    required this.onTicari,
    required this.avatarRadius,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.022), // ~18
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person, 
              size: avatarRadius * 0.91, // ~42
              color: const Color(0xFF0C5DB1)
            ),
          ),
          SizedBox(height: screenHeight * 0.017), // ~14
          Text(
            "Yeni Kullanıcı",
            style: TextStyle(
                color: Colors.white, 
                fontSize: screenWidth * 0.05, // ~20
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: screenHeight * 0.005), // ~4
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Farklı bir kullanıcı ile oturum açın",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9), 
                fontSize: screenWidth * 0.0375 // ~15
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.027), // ~22
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
            child: Row(
              children: [
                Expanded(
                    child: _PrimaryButton(
                      label: "BİREYSEL", 
                      onPressed: onBireysel,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                    )),
                const SizedBox(width: 12),
                Expanded(
                    child: _PrimaryButton(
                      label: "TİCARİ", 
                      onPressed: onTicari,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                    )),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.017), // ~14
          TextButton(
            onPressed: () {},
            child: Text(
              "ŞİFRE OLUŞTUR",
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
                fontSize: screenWidth * 0.035, // ~14
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double screenHeight;
  final double screenWidth;
  
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screenHeight * 0.065, // ~52
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0C5DB1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.04, // ~16
            fontWeight: FontWeight.w700
          ),
        ),
      ),
    );
  }
}

class _BottomCardsAndShortcuts extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  
  const _BottomCardsAndShortcuts({
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        16, 
        screenHeight * 0.017, // ~14
        16, 
        screenHeight * 0.012 // ~10
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                  child: _InfoCard(
                    title: "Mobil Borsa", 
                    icon: Icons.bar_chart,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  )),
              const SizedBox(width: 12),
              Expanded(
                  child: _InfoCard(
                    title: "Kampanyalar", 
                    icon: Icons.campaign,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  )),
            ],
          ),
          SizedBox(height: screenHeight * 0.02), // ~16
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickTile(
                icon: Icons.flash_on, 
                label: "FAST\nİşlemleri",
                screenWidth: screenWidth,
              ),
              _QuickTile(
                icon: Icons.stacked_line_chart, 
                label: "Fiyat ve\nOranlar",
                screenWidth: screenWidth,
              ),
              _QuickTile(
                icon: Icons.qr_code_2, 
                label: "Karekod\nİşlemleri",
                screenWidth: screenWidth,
              ),
              _QuickTile(
                icon: Icons.more_horiz, 
                label: "Daha\nFazlası",
                screenWidth: screenWidth,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01), // ~8
          Container(
            margin: EdgeInsets.only(
              top: screenHeight * 0.012, // ~10
              bottom: screenHeight * 0.005 // ~4
            ),
            width: screenWidth * 0.3, // ~120
            height: 5,
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double screenHeight;
  final double screenWidth;
  
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.08, // ~64
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            icon, 
            color: const Color(0xFF0C5DB1),
            size: screenWidth * 0.06, // ~24
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.0375, // ~15
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double screenWidth;
  
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon, 
          color: const Color(0xFF0C5DB1), 
          size: screenWidth * 0.07 // ~28
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center, 
          style: TextStyle(fontSize: screenWidth * 0.03) // ~12
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'close',
      '0',
      'back'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      padding: const EdgeInsets.only(bottom: 10),
      itemBuilder: (_, i) {
        final k = keys[i];
        if (k == 'close') {
          return _PadButton(
              child: Text(
                "KAPAT",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.032, // responsive
                ),
              ),
              onTap: onClose);
        }
        if (k == 'back') {
          return _PadButton(
              child: Icon(
                Icons.backspace_outlined,
                size: screenWidth * 0.06, // responsive
              ), 
              onTap: onBackspace);
        }
        return _PadButton(
          child: Text(
            k,
            style: TextStyle(
              fontSize: screenWidth * 0.05, // ~20 responsive
              fontWeight: FontWeight.w600
            ),
          ),
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
          borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}