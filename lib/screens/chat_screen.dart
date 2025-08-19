// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/message_model.dart';
import '../models/bot_badge_state.dart';
import '../services/api_service.dart'; // GÜNCEL: chat_service yerine api_service
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
    ChatMessage.bot('Merhaba! Size nasıl yardımcı olabilirim?',
        badge: BotBadgeState.sekreter),
  ];

  final ScrollController _scrollCtrl = ScrollController();

  bool _waitingReply = false;
  bool _hasConnection = true;
  bool _backendAvailable = true;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _scrollScheduled = false;

  static const _pastelPrimary = Color(0xFF8AB4F8); // user bubble rengi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom();
      _precacheBotAssets();
      _checkBackendHealth();
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

  // ---- Backend Sağlık Kontrolü ----
  Future<void> _checkBackendHealth() async {
    try {
      final healthy = await ApiService.checkHealth();
      if (mounted) {
        setState(() {
          _backendAvailable = healthy;
        });

        if (healthy) {
          _messages.add(
            ChatMessage.bot(
              '🚀 Backend sunucusu aktif! Artık gerçek AI yanıtları alabilirsiniz.',
              badge: BotBadgeState.connection,
            ),
          );
        } else {
          _messages.add(
            ChatMessage.bot(
              '⚠️ Backend sunucusuna bağlanılamıyor.\n\nLütfen backend sunucusunun çalıştığını kontrol edin:\n• Terminal: npm start\n• Port: 3001\n• URL: http://localhost:3001',
              badge: BotBadgeState.noConnection,
            ),
          );
        }
        _scheduleScrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendAvailable = false;
        });
      }
    }
  }

  // ---- Connectivity ----
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection == isConnected) return;

    setState(() {
      _hasConnection = isConnected;

      if (!isConnected) {
        _messages.add(
          ChatMessage.bot(
            'Bağlantı koptu. Çevrimdışısın.',
            badge: BotBadgeState.noConnection,
          ),
        );
      } else {
        _messages.add(
          ChatMessage.bot(
            'Wi-Fi geri geldi! Kaldığımız yerden devam edebiliriz. 🙌',
            badge: BotBadgeState.connection,
          ),
        );
        _checkBackendHealth();
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

  // ---- Messaging with Backend ----
  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

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

    if (!_backendAvailable) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(ChatMessage.bot(
          '🔧 Sunucu şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
          badge: BotBadgeState.noConnection,
        ));
      });
      _scheduleScrollToBottom();
      return;
    }

    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _waitingReply = true;
    });
    _scheduleScrollToBottom();

    try {
      final response = await ApiService.sendMessage(
        message: trimmed,
        userId: 'team1',
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage.bot(
              response.message,
              badge: response.badgeState,
            ),
          );
          _waitingReply = false;
        });
        _scheduleScrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.bot(
            'Hata: ${e.message}',
            badge: BotBadgeState.noConnection,
          ));
          _waitingReply = false;
          if (e.statusCode == 0) {
            _backendAvailable = false;
          }
        });
        _scheduleScrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.bot(
            'Beklenmeyen bir hata oluştu. Lütfen tekrar dener misiniz?',
            badge: BotBadgeState.noConnection,
          ));
          _waitingReply = false;
        });
        _scheduleScrollToBottom();
      }
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
            icon: const Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 0, 110, 255)),
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
              const Text(
                'Kaptan',
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 110, 255),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _backendAvailable ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: Color.fromARGB(255, 0, 110, 255)),
              onPressed: _checkBackendHealth,
              tooltip: 'Sunucu durumunu kontrol et',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert,
                  color: Color.fromARGB(255, 0, 110, 255)),
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
                      // 🔵 Arka plan görseli tüm ekranı kaplar
                      Positioned.fill(
                        child: Image.asset(
                          "lib/assets/images/captain/chat/Chatbot-Background.jpeg",
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 🔵 Hafif beyaz overlay (okunabilirlik için)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      // 🔵 Chat içerik
                      Column(
                        children: [
                          if (!_backendAvailable)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: Colors.orange.shade100.withOpacity(0.9),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Backend sunucusu çalışmıyor. "npm start" ile başlatın.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _checkBackendHealth,
                                    child: const Text('Yeniden Dene'),
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
                            enabled: !_waitingReply && _backendAvailable,
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
          'yazıyor...',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
