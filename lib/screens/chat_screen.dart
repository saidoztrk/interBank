// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/message_model.dart';
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
    ChatMessage.bot('Kaptanınız konuşuyor! Size nasıl yardımcı olabilirim?'),
  ];

  final ScrollController _scrollCtrl = ScrollController();
  bool _waitingReply = false;
  bool _hasConnection = true;

  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _scrollScheduled = false;

  static const _pastelBg = Color(0xFFF7F9FC);
  static const _pastelPrimary = Color(0xFF8AB4F8);

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

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection == isConnected) return;

    setState(() {
      _hasConnection = isConnected;
      _messages.add(
        ChatMessage.bot(
          isConnected
              ? '🔌 Bağlantı geri geldi! Kaldığımız yerden devam edebiliriz. 🙌'
              : 'Bağlantı koptu. Çevrimdışıyız.',
        ),
      );
    });

    _scheduleScrollToBottom();
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  Future<void> _precacheBotAssets() async {
    const asset = 'lib/assets/images/chatbot/icons8-captain-48.png';
    precacheImage(const AssetImage(asset), context);
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

  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!_hasConnection) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(ChatMessage.bot('Ağ hatası: çevrimdışısın.'));
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
      final reply = await _fakeBotReply(trimmed);
      setState(() {
        _messages.add(ChatMessage.bot(reply));
        _waitingReply = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage.bot(
            'Ağ hatası oluştu. Lütfen tekrar dener misin?'));
        _waitingReply = false;
      });
    }
    _scheduleScrollToBottom();
  }

  Future<String> _fakeBotReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'Şunları söyledin: "$userText"';
  }

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
        backgroundColor: _pastelBg,
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          title: const Text(
            'Kaptan',
            style: TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
                fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
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
                          itemCount: _messages.length + (_waitingReply ? 1 : 0),
                          itemBuilder: (context, index) {
                            final typingItem =
                                _waitingReply && index == _messages.length;
                            if (typingItem) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 18, bottom: 6),
                                child: _TypingIndicator(),
                              );
                            }
                            return ChatBubble(message: _messages[index]);
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
      children: const [
        CircleAvatar(
          radius: 21,
          backgroundColor: Colors.transparent,
          backgroundImage:
              AssetImage('lib/assets/images/chatbot/icons8-captain-48.png'),
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
