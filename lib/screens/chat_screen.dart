// lib/screens/chat_screen.dart — MAYDAY brand, QR akışları kaldırıldı, placeholder cevap filtresi + BG image

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

  final List<ChatMessage> _messages = [
    ChatMessage.bot(
      '🏦 Merhaba! Ben $_brandName asistanınızım. Banking işlemlerinizde size nasıl yardımcı olabilirim?',
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

    if (widget.initialSessionId != null) {
      ApiServiceManager.setCurrentSessionId(widget.initialSessionId!);
    }

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
              '❌ MCP Agent şu an erişilemiyor.\n\n'
              'Kontrol listesi:\n'
              '• MCP Agent (cloud): mcp-agent-api.azurewebsites.net',
              badge: BotBadgeState.noConnection,
            ),
          );
        });
      } else {
        if (_serviceHealth.mcpAgentAvailable && !_announcedMcpUp) {
          _announcedMcpUp = true;
          setState(() {
            _messages.add(
              ChatMessage.bot(
                'MCP Agent bağlantısı başarılı!',
                badge: BotBadgeState.connection,
              ),
            );
          });
        }
      }

      _scheduleScrollToBottom();
    } catch (e) {
      debugPrint('❌ Service health check error: $e');
    }
  }

  // ---- Bağlantı Yönetimi ----
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
  }

  // ---- Mesaj Gönderimi ----
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
            '🔧 MCP Agent kullanılamıyor. Lütfen daha sonra yeniden deneyin.',
            badge: BotBadgeState.noConnection,
          ),
        );
      });
      _scheduleScrollToBottom();
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
        sessionId: ApiServiceManager.getCurrentSessionId(),
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

  String _getServiceDisplayName(ServiceType service) => 'MCP Agent';

  Color _getServiceStatusColor() {
    if (!_serviceHealth.anyServiceAvailable) return Colors.red;
    final up = _serviceHealth.mcpAgentAvailable;
    return up ? Colors.green : Colors.orange;
  }

  // ---- Oturum İşlemleri ----
  Future<void> _startNewSession() async {
    try {
      final newId = await ApiServiceManager.startNewSession();
      ApiServiceManager.setCurrentSessionId(newId);

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage.bot(
            '🆕 Yeni sohbet oturumu başlatıldı. Nasıl yardımcı olabilirim?',
            badge: BotBadgeState.sekreter,
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
          const SnackBar(content: Text('Geçerli oturum temizlendi')),
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
          const SnackBar(content: Text('Kayıtlı oturum yok')),
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

  // ---- Build ----
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
              const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    AssetImage('lib/assets/images/captain/captain.png'),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    _brandName,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getServiceDisplayName(_activeService),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getServiceStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
            ),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'new_session',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text('Yeni Sohbet'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'session_history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('Oturum Geçmişi'),
                    ],
                  ),
                ),
                PopupMenuItem(
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
                    // === Arka plan görseli (sadece görüntü) ===
                    Positioned.fill(
                      child: Image.asset(
                        _bgPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    // === İçerik ===
                    SafeArea(
                      child: Column(
                        children: [
                          if (!_serviceHealth.anyServiceAvailable)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: Colors.red.shade100,
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'MCP Agent aktif değil.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkAllServicesHealth,
                                    child: const Text('Tekrar Dene'),
                                  ),
                                ],
                              ),
                            )
                          else if (!_serviceHealth.mcpAgentAvailable)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: Colors.orange.shade100,
                              child: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'MCP Agent erişilemiyor. Lütfen daha sonra deneyin.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkAllServicesHealth,
                                    child: const Text('Yenile'),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 8),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount:
                                  _messages.length + (_waitingReply ? 1 : 0),
                              itemBuilder: (context, index) {
                                final typingItem =
                                    _waitingReply && index == _messages.length;
                                if (typingItem) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(left: 18, bottom: 6),
                                    child: _TypingIndicator(),
                                  );
                                }
                                final msg = _messages[index];
                                return ChatBubble(message: msg);
                              },
                            ),
                          ),
                          MessageInput(
                            enabled: !_waitingReply &&
                                _serviceHealth.anyServiceAvailable &&
                                _serviceHealth.mcpAgentAvailable,
                            onSend: _sendUserMessage,
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

// ---- Typing indicator ----
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Colors.transparent,
          backgroundImage:
              AssetImage('lib/assets/images/captain/captain_writing.png'),
        ),
        SizedBox(width: 10),
        _TypingBubble(),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
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
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Agent çalışıyor...',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
