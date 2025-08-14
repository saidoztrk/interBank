// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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
    ChatMessage.bot('Merhaba! Size nasıl yardımcı olabilirim?'),
  ];

  final ScrollController _scrollCtrl = ScrollController();
  bool _waitingReply = false;

  bool _hasConnection = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Uygulama başladığında ve durum değiştiğinde interneti kontrol et
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

  @override
  void didChangeMetrics() {
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  // Bağlantı durumunu güncelleyen metot (List<ConnectivityResult> alacak şekilde güncellendi)
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool isConnected = !result.contains(ConnectivityResult.none);
    if (_hasConnection != isConnected) {
      setState(() {
        _hasConnection = isConnected;
      });
    }
  }

  // İlk bağlantı kontrolünü yapan metot (List<ConnectivityResult> döndürecek şekilde güncellendi)
  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty || !_hasConnection) return;

    setState(() {
      _messages.add(ChatMessage.user(text));
      _waitingReply = true;
    });
    _scrollToBottom();

    final reply = await _fakeBotReply(text);

    setState(() {
      _messages.add(ChatMessage.bot(reply));
      _waitingReply = false;
    });
    _scrollToBottom();
  }

  Future<String> _fakeBotReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'Şunları söyledin: "$userText"';
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasConnection) {
      return NoConnectionScreen(onRetry: _checkInitialConnection);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Asistan',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 8),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ChatBubble(message: msg);
                  },
                ),
              ),
              if (_waitingReply)
                const Padding(
                  padding: EdgeInsets.only(left: 18, bottom: 6),
                  child: _TypingIndicator(),
                ),
              MessageInput(
                enabled: !_waitingReply,
                onSend: _sendUserMessage,
              ),
            ],
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
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.smart_toy, size: 12, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'yazıyor...',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
