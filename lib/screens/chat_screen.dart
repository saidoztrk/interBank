// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/message_model.dart';
import '../models/bot_badge_state.dart';
import '../services/mcp_api_service.dart'; // MCP Agent servisi
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import 'no_connection_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [
    ChatMessage.bot(
      '🏦 Merhaba! Ben CaptainBank asistanınızım. Banking işlemlerinizde size nasıl yardımcı olabilirim?',
      badge: BotBadgeState.sekreter,
    ),
  ];

  final ScrollController _scrollCtrl = ScrollController();

  bool _waitingReply = false;
  bool _hasConnection = true;

  // MCP durumları
  bool _mcpAgentAvailable = true;   // MCP Agent ayakta mı?
  bool _mcpServersHealthy = false;  // MCP’ye bağlı servisler ayakta mı?

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Login’den gelecek; şimdilik sabit
  int get currentUserId => 12345;

  // Scroll titremesini azaltmak için throttle
  bool _scrollScheduled = false;

  // Tema
  static const _pastelPrimary = Color(0xFF8AB4F8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom();
      _precacheBotAssets();
      _checkMcpAgentHealth(); // MCP Agent sağlık kontrolü
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

  // ---- MCP Agent Sağlık Kontrolü ----
  Future<void> _checkMcpAgentHealth() async {
    try {
      // Agent
      final agentHealthy = await McpApiService.checkHealth();

      // MCP sunucuları
      final mcpStatus = await McpApiService.checkMcpStatus();
      final mcpHealthy = mcpStatus.values.any((status) => status);

      if (!mounted) return;
      setState(() {
        _mcpAgentAvailable = agentHealthy;
        _mcpServersHealthy = mcpHealthy;
      });

      if (agentHealthy) {
        _messages.add(
          ChatMessage.bot(
            mcpHealthy
                ? '🚀 MCP Agent bağlantısı başarılı! Banking servislerine erişebiliyorum.'
                : '⚠️ MCP Agent çalışıyor ancak banking sunucularına bağlanamıyor.\n\nMCP Server (port 8080) çalışıyor mu kontrol edin.',
            badge: mcpHealthy ? BotBadgeState.connection : BotBadgeState.thinking,
          ),
        );
      } else {
        _messages.add(
          ChatMessage.bot(
            '❌ MCP Agent sunucusuna bağlanılamıyor.\n\nKontrol listesi:\n• python mcp_agent/agent_api.py\n• Port: 8081\n• URL: http://127.0.0.1:8081',
            badge: BotBadgeState.noConnection,
          ),
        );
      }
      _scheduleScrollToBottom();
    } on McpApiException catch (e) {
      if (!mounted) return;
      setState(() => _mcpAgentAvailable = false);
      _messages.add(
        ChatMessage.bot(
          'Hata: ${e.message}',
          badge: BotBadgeState.noConnection,
        ),
      );
      _scheduleScrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _mcpAgentAvailable = false);
    }
  }

  // ---- Connectivity (v6) ----
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
        _checkMcpAgentHealth(); // Bağlantı gelince tekrar kontrol
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
    ];
    for (final a in assets) {
      precacheImage(AssetImage(a), context);
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

  // ---- MCP Agent ile Messaging ----
  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Bağlantı kontrolü
    if (!_hasConnection) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(ChatMessage.bot(
          'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
          badge: BotBadgeState.noConnection,
        ));
      });
      _scheduleScrollToBottom();
      return;
    }

    // MCP Agent kontrolü
    if (!_mcpAgentAvailable) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(ChatMessage.bot(
          '🔧 MCP Agent şu anda kullanılamıyor. Lütfen sunucuyu başlatın.',
          badge: BotBadgeState.noConnection,
        ));
      });
      _scheduleScrollToBottom();
      return;
    }

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _waitingReply = true;
    });
    _scheduleScrollToBottom();

    try {
      // Geçici “düşünüyorum” mesajı
      setState(() {
        _messages.add(ChatMessage.bot(
          'Düşünüyorum...',
          badge: BotBadgeState.thinking,
        ));
      });
      _scheduleScrollToBottom();

      // MCP Agent'a istek gönder
      final response = await McpApiService.sendMessage(
        message: trimmed,
        userId: currentUserId,
      );

      if (!mounted) return;
      setState(() {
        // Thinking mesajını kaldır
        if (_messages.isNotEmpty &&
            _messages.last.text == 'Düşünüyorum...' &&
            _messages.last.sender == Sender.bot) {
          _messages.removeLast();
        }

        _messages.add(
          ChatMessage.bot(
            response.message,
            badge: response.badgeState,
          ),
        );
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    } on McpApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.text == 'Düşünüyorum...' &&
            _messages.last.sender == Sender.bot) {
          _messages.removeLast();
        }
        _messages.add(ChatMessage.bot(
          'Hata: ${e.message}',
          badge: BotBadgeState.noConnection,
        ));
        _waitingReply = false;

        if (e.statusCode == 0) {
          _mcpAgentAvailable = false;
        }
      });
      _scheduleScrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.text == 'Düşünüyorum...' &&
            _messages.last.sender == Sender.bot) {
          _messages.removeLast();
        }
        _messages.add(ChatMessage.bot(
          'Beklenmeyen bir hata oluştu. Lütfen tekrar dener misiniz?',
          badge: BotBadgeState.noConnection,
        ));
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
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
            children: const [
              Icon(Icons.smart_toy, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'CaptainBank AI',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            // Durum noktası
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _mcpAgentAvailable && _mcpServersHealthy
                      ? Colors.green
                      : _mcpAgentAvailable
                          ? Colors.orange
                          : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _checkMcpAgentHealth,
              tooltip: 'MCP Agent durumunu kontrol et',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
        body: !_hasConnection
            ? NoConnectionScreen(onRetry: _checkInitialConnection)
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // 🔵 Arka plan görseli tüm ekranı kaplar (Current’tan alındı)
                      Positioned.fill(
                        child: Image.asset(
                          "lib/assets/images/captain/chat/Chatbot-Background.jpeg",
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 🔵 Okunabilirlik için beyaz overlay (Current’tan alındı)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      // 🔵 İçerik
                      Column(
                        children: [
                          // MCP durum banner’ları
                          if (!_mcpAgentAvailable)
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
                                      'MCP Agent offline. "python mcp_agent/agent_api.py" ile başlatın.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkMcpAgentHealth,
                                    child: const Text('Tekrar Dene'),
                                  ),
                                ],
                              ),
                            )
                          else if (!_mcpServersHealthy)
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
                                      'MCP sunucuları offline. Banking servisleri sınırlı.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkMcpAgentHealth,
                                    child: const Text('Kontrol Et'),
                                  ),
                                ],
                              ),
                            ),

                          // Mesaj listesi
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

                          // Girdi alanı
                          MessageInput(
                            enabled: !_waitingReply && _mcpAgentAvailable,
                            onSend: _sendUserMessage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Typing indicator - MCP Agent düşünüyor
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
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
          'MCP Agent çalışıyor...',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
