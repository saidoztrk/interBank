// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/message_model.dart';
import '../models/bot_badge_state.dart';
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
    ChatMessage.bot('Merhaba! Size nasıl yardımcı olabilirim?'),
  ];

  final ScrollController _scrollCtrl = ScrollController();

  bool _waitingReply = false;
  bool _hasConnection = true;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Scroll titremesini önlemek için planlı (throttled) kaydırma
  bool _scrollScheduled = false;

  // Pastel renkler
  static const _pastelBg = Color(0xFFF7F9FC); // arka plan
  static const _pastelPrimary = Color(0xFF8AB4F8); // user bubble rengi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom();
      _precacheBotAssets();
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

  // ---- Connectivity (v6) ----
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection != isConnected) {
      setState(() => _hasConnection = isConnected);
      if (!isConnected) {
        _messages
            .add(ChatMessage.bot('Bağlantı yok', badge: BotBadgeState.error));
        _scheduleScrollToBottom();
      }
    }
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  // ---- UI helpers ----
  Future<void> _precacheBotAssets() async {
    const assets = [
      'lib/assets/images/chatbot/tele_sekreter.png', // default
      'lib/assets/images/chatbot/thinking.png', // düşünürken
      'lib/assets/images/chatbot/404_hata.png', // ağ hatası
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

  // ---- Messaging ----
  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!_hasConnection) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(ChatMessage.bot(
          'Ağ hatası: çevrimdışısın.',
          badge: BotBadgeState.error, // 404_hata.png
        ));
      });
      _scheduleScrollToBottom();
      return;
    }

    // Titremesiz: sadece user mesajını ekle + typing item'ı listede göstereceğiz
    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _waitingReply = true;
    });
    _scheduleScrollToBottom();

    try {
      // TODO: gerçek backend çağrını buraya koy
      final reply = await _fakeBotReply(trimmed);

      setState(() {
        _messages.add(ChatMessage.bot(reply,
            badge: BotBadgeState.teleSekreter)); // default rozet
        _waitingReply = false; // typing kalkar
      });
      _scheduleScrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage.bot(
          'Ağ hatası oluştu. Lütfen tekrar dener misin?',
          badge: BotBadgeState.error,
        ));
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    }
  }

  Future<String> _fakeBotReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'Şunları söyledin: "$userText"';
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    // ChatBubble user rengi Theme.primaryColor'dan aldığı için burada pastel primary veriyoruz.
    final theme = Theme.of(context).copyWith(
      primaryColor: _pastelPrimary,
      colorScheme:
          Theme.of(context).colorScheme.copyWith(primary: _pastelPrimary),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _pastelBg,
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
          title: const Text(
            'Asistan',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          actions: [
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
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 8),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Typing indicator'ı da liste elemanı olarak ekle
                          itemCount: _messages.length + (_waitingReply ? 1 : 0),
                          itemBuilder: (context, index) {
                            final bool typingItem =
                                _waitingReply && index == _messages.length;
                            if (typingItem) {
                              // DÜŞÜNÜRKEN: thinking.png
                              return const Padding(
                                padding: EdgeInsets.only(left: 18, bottom: 6),
                                child: _TypingIndicator(),
                              );
                            }
                            final msg = _messages[index];
                            return ChatBubble(message: msg);
                          },
                        ),
                      ),
                      MessageInput(
                        enabled: !_waitingReply,
                        onSend: _sendUserMessage,
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
        // DÜŞÜNÜRKEN: thinking.png
        CircleAvatar(
          radius: 21, // 1.5x büyütülmüş
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage('lib/assets/images/chatbot/thinking.png'),
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
        color: Colors.white, // pastel zeminde hafif balon
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 1)),
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
