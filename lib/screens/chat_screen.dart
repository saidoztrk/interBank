// lib/screens/chat_screen.dart — Session bazlı sohbet geçmişi yönetimi

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Servis & modeller
import 'package:interbank/models/session_info.dart';
import 'package:interbank/models/message_model.dart';
import 'package:interbank/models/bot_badge_state.dart';
import 'package:interbank/services/api_service_manager.dart';
import 'package:interbank/services/session_manager.dart';
import 'package:interbank/widgets/chat_bubble.dart';
import 'package:interbank/widgets/message_input.dart';
import 'package:interbank/screens/no_connection_screen.dart';
import 'dart:math' as math;

class ChatScreen extends StatefulWidget {
  final String? initialSessionId;
  final ServiceType? preferredService; // geriye uyumluluk için

  const ChatScreen({
    super.key,
    this.initialSessionId,
    this.preferredService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const _brandName = 'MAYDAY';
  static const _pastelPrimary = Color(0xFF8AB4F8);
  static const _bgPath =
      'lib/assets/images/captain/chat/Chatbot-Background.jpeg';

  // Her yeni session'da karşılama mesajı ile başla
  List<ChatMessage> _messages = [
    ChatMessage.bot(
      '👋 Merhaba! Ben MAYDAY, sizin kişisel bankacılık asistanınızım.\n\n'
      '💳 Hesap bakiyelerinizi öğrenebilir\n'
      '📊 İşlem geçmişinizi inceleyebilir\n'
      '💸 Para transferi yapabilir\n'
      '🔍 Bankacılık hizmetleri hakkında bilgi alabilirsiniz\n\n'
      'Size nasıl yardımcı olabilirim?',
      badge: BotBadgeState.sekreter,
    ),
  ];

  final ScrollController _scrollCtrl = ScrollController();

  bool _waitingReply = false;
  bool _hasConnection = true;

  // Servis sağlık durumu (yalnız MCP)
  ServiceHealthStatus _serviceHealth = const ServiceHealthStatus(
    mcpAgentAvailable: false,
    externalApiAvailable: false, // UI geriye uyumluluk alanı
  );

  // Artık tek servis: MCP
  final ServiceType _activeService = ServiceType.mcpAgent;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Scroll titremesini azaltmak için throttle
  bool _scrollScheduled = false;

  // Bağlantı başarılı mesajını bir kez gösterme guard'ı
  bool _announcedMcpUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Session kontrolü ve başlatma
    _ensureSessionActive();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom();
      _precacheBotAssets();
      _checkAllServicesHealth();
    });

    _checkInitialConnection();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    _subscription.cancel();
    super.dispose();
  }@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Uygulama arkaplan/kapatma durumunda mesajları temizle
        print('[ChatScreen] App lifecycle changed - clearing messages');
        _clearLocalMessages();
        break;
      case AppLifecycleState.resumed:
        // Uygulama tekrar aktif olduğunda session kontrolü yap
        _ensureSessionActive();
        _checkAllServicesHealth();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Geçici durumlar için özel işlem yapma
        break;
    }
  }

  // Session'ın aktif olduğundan emin ol
  void _ensureSessionActive() {
    final currentSessionId = ApiServiceManager.getCurrentSessionId();
    if (currentSessionId == null) {
      // Session yoksa yeni bir tane başlat
      ApiServiceManager.initializeSession().then((sessionId) {
        print('[ChatScreen] New session initialized: $sessionId');
        // Yeni session ile beraber mesajları temizle ve karşılama mesajı ekle
        _resetMessagesForNewSession();
      }).catchError((e) {
        print('[ChatScreen] Session initialization error: $e');
      });
    }
  }

  // Lokal mesajları temizle (session kapandığında)
  void _clearLocalMessages() {
    setState(() {
      _messages = [
        ChatMessage.bot(
          '👋 Merhaba! Ben MAYDAY, sizin kişisel bankacılık asistanınızım.\n\n'
          '💳 Hesap bakiyelerinizi öğrenebilir\n'
          '📊 İşlem geçmişinizi inceleyebilir\n'
          '💸 Para transferi yapabilir\n'
          '🔍 Bankacılık hizmetleri hakkında bilgi alabilirsiniz\n\n'
          'Size nasıl yardımcı olabilirim?',
          badge: BotBadgeState.sekreter,
        ),
      ];
    });
  }

  // Yeni session için mesajları sıfırla
  void _resetMessagesForNewSession() {
    setState(() {
      _messages = [
        ChatMessage.bot(
          '🔄 Yeni oturum başlatıldı.\n\n'
          '👋 Ben MAYDAY, sizin kişisel bankacılık asistanınızım.\n\n'
          '💳 Hesap bakiyelerinizi öğrenebilir\n'
          '📊 İşlem geçmişinizi inceleyebilir\n'
          '💸 Para transferi yapabilir\n'
          '🔍 Bankacılık hizmetleri hakkında bilgi alabilirsiniz\n\n'
          'Size nasıl yardımcı olabilirim?',
          badge: BotBadgeState.connection,
        ),
      ];
    });
    _scheduleScrollToBottom();
  }

  // ---- Servis Sağlık Kontrolü (yalnız MCP) ----
  Future<void> _checkAllServicesHealth() async {
    try {
      final healthStatus = await ApiServiceManager.checkAllServicesHealth();
      if (!mounted) return;

      setState(() {
        _serviceHealth = healthStatus;
      });

      if (!_serviceHealth.anyServiceAvailable) {
        setState(() {
          _messages.add(
            ChatMessage.bot(
              '⚠️ Sistem geçici olarak erişilemiyor. Lütfen daha sonra tekrar deneyin.',
              badge: BotBadgeState.noConnection,
            ),
          );
        });
      } else {
        if (_serviceHealth.mcpAgentAvailable && !_announcedMcpUp) {
          _announcedMcpUp = true;
          // Bağlantı başarılı mesajı kaldırıldı
        }
      }

      _scheduleScrollToBottom();
    } catch (e) {
      debugPrint('⚠️ Service health check error: $e');
    }
  }// ---- Bağlantı Yönetimi ----
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection == isConnected) return;

    setState(() {
      _hasConnection = isConnected;

      if (!isConnected) {
        _messages.add(
          ChatMessage.bot(
            'İnternet bağlantısı koptu. Çevrimdışısınız.',
            badge: BotBadgeState.noConnection,
          ),
        );
      } else {
        _messages.add(
          ChatMessage.bot(
            'İnternet bağlantısı geri geldi! 🌐',
            badge: BotBadgeState.connection,
          ),
        );
        _checkAllServicesHealth();
      }
    });

    _scheduleScrollToBottom();
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  Future<void> _precacheBotAssets() async {
    const assets = [
      'lib/assets/images/captain/captain.png',
      'lib/assets/images/captain/captain_thinking.png',
      'lib/assets/images/captain/captain_writing.png',
      'lib/assets/images/captain/captain_connection.png',
      'lib/assets/images/captain/captain_noconnection.png',
      'lib/assets/images/captain/captain_sekreter.png',
      _bgPath,
    ];
    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e) {
        debugPrint('Asset precache hatası: $asset - $e');
      }
    }
  }

  void _scheduleScrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if ((target - _scrollCtrl.position.pixels).abs() < 2) return;
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ---- Placeholder/ yönlendirme mesajlarını filtrele ----
  bool _shouldSuppressBotText(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return true;
    // örnek: "Account Info Agent'e yönlendiriyorum. Lütfen bekleyiniz."
    final patterns = [
      'yönlendiriyorum',
      'bekleyiniz',
      'bekleyin',
      'redirect',
      'forwarding',
      'yönlendirilecek',
      'agent\'e',
      'agente',
    ];
    final hit = patterns.any((p) => t.contains(p));
    // çok kısa ve yönlendirme benzeri ifadeler
    if (hit && t.length < 120) return true;
    return false;
  }// ---- Mesaj Gönderimi ----
  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Bağlantı kontrol
    if (!_hasConnection) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(
          ChatMessage.bot(
            'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
            badge: BotBadgeState.noConnection,
          ),
        );
      });
      _scheduleScrollToBottom();
      return;
    }

    // MCP uygun mu?
    if (!_serviceHealth.anyServiceAvailable ||
        !_serviceHealth.mcpAgentAvailable) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(
          ChatMessage.bot(
            '🔧 Sistem şu anda kullanılamıyor. Lütfen daha sonra yeniden deneyin.',
            badge: BotBadgeState.noConnection,
          ),
        );
      });
      _scheduleScrollToBottom();
      return;
    }

    // Session kontrolü
    final sessionId = ApiServiceManager.getCurrentSessionId();
    if (sessionId == null) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(
          ChatMessage.bot(
            'Oturum bilgisi bulunamadı. Yeni oturum başlatılıyor...',
            badge: BotBadgeState.connection,
          ),
        );
      });
      _scheduleScrollToBottom();

      // Yeni session başlat
      try {
        await ApiServiceManager.initializeSession();
        _resetMessagesForNewSession();
      } catch (e) {
        setState(() {
          _messages.add(
            ChatMessage.bot(
              'Oturum başlatılamadı. Lütfen uygulamayı yeniden başlatın.',
              badge: BotBadgeState.noConnection,
            ),
          );
        });
        _scheduleScrollToBottom();
      }
      return;
    }

    // customerNo null kontrolü
    final custNo = SessionManager.customerNo;
    if (custNo == null) {
      setState(() {
        _messages.add(
          ChatMessage.bot(
            'Oturum bilgisi bulunamadı (customerNo boş). Lütfen yeniden giriş yapın.',
            badge: BotBadgeState.noConnection,
          ),
        );
      });
      _scheduleScrollToBottom();
      return;
    }

    // Kullanıcı mesajını ekle + typing indicator
    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _waitingReply = true;
    });
    _scheduleScrollToBottom();

    try {
      final response = await ApiServiceManager.sendMessage(
        message: trimmed,
        customerNo: custNo,
        sessionId: sessionId,
      );

      if (!mounted) return;

      // Placeholder ise gösterme; değilse ekle
      if (!_shouldSuppressBotText(response.message)) {
        setState(() {
          _messages.add(
            ChatMessage.bot(response.message, badge: response.badgeState),
          );
        });
      }
      setState(() => _waitingReply = false);
      _scheduleScrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot('Hata: ${e.message}',
              badge: BotBadgeState.noConnection),
        );
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot(
            'Beklenmeyen bir hata oluştu. Lütfen tekrar dener misiniz?',
            badge: BotBadgeState.noConnection,
          ),
        );
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    }
  }

  String _getServiceDisplayName(ServiceType service) => 'Bankacılık Asistanı';

  Color _getServiceStatusColor() {
    if (!_serviceHealth.anyServiceAvailable) return Colors.red;
    final up = _serviceHealth.mcpAgentAvailable;
    return up ? Colors.green : Colors.orange;
  }// ---- Oturum İşlemleri ----
  Future<void> _startNewSession() async {
    try {
      // Eski session'ı sonlandır ve yeni session başlat
      final newId = await ApiServiceManager.startNewSession();

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage.bot(
            '🆕 Yeni sohbet oturumu başlatıldı.\n\n'
            '👋 Ben MAYDAY, sizin kişisel bankacılık asistanınızım. '
            'Size nasıl yardımcı olabilirim?',
            badge: BotBadgeState.connection,
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni oturum başlatıldı')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturum başlatılırken hata: $e')),
      );
    }
  }

  Future<void> _clearCurrentSession() async {
    try {
      // Session geçmişini temizle (session'ı aktif bırak)
      await ApiServiceManager.clearCurrentSession();

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage.bot(
            '🧹 Sohbet geçmişi temizlendi. Yeni bir soruyla başlayalım!',
            badge: BotBadgeState.sekreter,
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sohbet geçmişi temizlendi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Temizlenemedi: $e')),
      );
    }
  }

  Future<void> _showSessionHistory() async {
    try {
      final sessions = await ApiServiceManager.listSessions(
        userId: SessionManager.customerNo ?? 0,
      );
      if (!mounted) return;

      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Aktif session bazlı çalışma nedeniyle geçmiş oturumlar mevcut değil'),
          ),
        );
        return;
      }

      final selected = await showDialog<SessionInfo>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oturum Geçmişi'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                final s = sessions[i];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(s.title ?? 'Oturum ${s.id}'),
                  subtitle: Text(s.updatedAt?.toString() ?? ''),
                  onTap: () => Navigator.of(ctx).pop(s),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );

      if (selected != null) {
        ApiServiceManager.setCurrentSessionId(selected.id);
        setState(() {
          _messages.clear();
          _messages.add(
            ChatMessage.bot(
              '📂 "${selected.title ?? selected.id}" oturumu yüklendi. Devam edebilirsiniz.',
              badge: BotBadgeState.connection,
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturumlar alınamadı: $e')),
      );
    }
  }

  // ---- Responsive Helper ----
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 600;
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 400;// ---- Build ----
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: _pastelPrimary,
      colorScheme:
          Theme.of(context).colorScheme.copyWith(primary: _pastelPrimary),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kaptan görünümlü küçük logo (asset)
              CircleAvatar(
                radius: _isSmallScreen ? 8 : 10,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    const AssetImage('lib/assets/images/captain/captain.png'),
              ),
              SizedBox(width: _isSmallScreen ? 6 : 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _brandName,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: _isSmallScreen ? 14 : 16,
                      ),
                    ),
                    if (!_isSmallScreen)
                      Text(
                        _getServiceDisplayName(_activeService),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Servis durumu göstergesi kaldırıldı
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _checkAllServicesHealth,
              tooltip: 'Bağlantıyı kontrol et',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'new_session':
                    _startNewSession();
                    break;
                  case 'session_history':
                    _showSessionHistory();
                    break;
                  case 'clear_history':
                    _clearCurrentSession();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new_session',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text('Yeni Sohbet'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'session_history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('Oturum Geçmişi'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_history',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 8),
                      Text('Geçmişi Temizle'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: !_hasConnection
            ? NoConnectionScreen(onRetry: _checkInitialConnection)
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    // === Arka plan görseli (responsive) ===
                    Positioned.fill(
                      child: Image.asset(
                        _bgPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey.shade100),
                      ),
                    ),
                    // === İçerik (responsive) ===
                    SafeArea(
                      child: Column(
                        children: [
                          // Servis durumu uyarı banner'ı (responsive) - Kısaltıldı
                          if (!_serviceHealth.anyServiceAvailable)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(_isSmallScreen ? 8 : 12),
                              color: Colors.red.shade100,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: _isSmallScreen ? 18 : 24,
                                  ),
                                  SizedBox(width: _isSmallScreen ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      'Sistem geçici olarak erişilemiyor.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: _isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkAllServicesHealth,
                                    child: Text(
                                      'Tekrar Dene',
                                      style: TextStyle(
                                        fontSize: _isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Chat mesajları listesi (responsive)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return ListView.builder(
                                  controller: _scrollCtrl,
                                  physics: const ClampingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: _isSmallScreen ? 4 : 8,
                                    left: _isSmallScreen ? 4 : 8,
                                    right: _isSmallScreen ? 4 : 8,
                                  ),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: _messages.length +
                                      (_waitingReply ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    final typingItem = _waitingReply &&
                                        index == _messages.length;
                                    if (typingItem) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: _isSmallScreen ? 12 : 18,
                                          bottom: _isSmallScreen ? 4 : 6,
                                        ),
                                        child: const _TypingIndicator(),
                                      );
                                    }
                                    final msg = _messages[index];
                                    return ChatBubble(message: msg);
                                  },
                                );
                              },
                            ),
                          ),
                          // Mesaj girişi (responsive)
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: _isLargeScreen ? 800 : double.infinity,
                            ),
                            child: MessageInput(
                              enabled: !_waitingReply &&
                                  _serviceHealth.anyServiceAvailable &&
                                  _serviceHealth.mcpAgentAvailable,
                              onSend: _sendUserMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---- Hareketli 3 nokta typing indicator (responsive) ----
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Kaptan icon'u - kare şeklinde
        Container(
          width: isSmallScreen ? 32 : 42,
          height: isSmallScreen ? 32 : 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Kare şeklinde
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/assets/images/captain/captain_writing.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 6 : 10),
        const _AnimatedDots(), // Hareketli 3 nokta
      ],
    );
  }
}

// Hareketli 3 nokta animasyonu
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 5 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 3),
                _buildDot(1),
                const SizedBox(width: 3),
                _buildDot(2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final progress = _animation.value;
    final delay = index * 0.2;
    final dotProgress = ((progress - delay) % 1.0).clamp(0.0, 1.0);
    
    final opacity = (math.sin(dotProgress * math.pi)).clamp(0.3, 1.0);
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black87.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// math import'u için:
