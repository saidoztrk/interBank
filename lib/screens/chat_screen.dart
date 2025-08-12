// lib/screens/chat_screen.dart
//
// Basit sohbet arayüzü.
// MCP/LLM entegrasyonu için _fakeBotReply yerine gerçek API çağrını kullan.
// Örn: final reply = await _sendToBackend(text);

import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [
    ChatMessage.bot('Hello! How can I help you?'),
  ];

  final ScrollController _scrollCtrl = ScrollController();
  bool _waitingReply = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // İlk frame sonrası alta kay
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Klavye açılıp kapanınca da alta kaydır
  @override
  void didChangeMetrics() {
    // Biraz gecikme ile, yoksa ölçüler daha oturmamış oluyor
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  Future<void> _sendUserMessage(String text) async {
    setState(() {
      _messages.add(ChatMessage.user(text));
      _waitingReply = true;
    });
    _scrollToBottom();

    // TODO: Gerçek backend çağrısı ile değiştir
    final reply = await _fakeBotReply(text);

    setState(() {
      _messages.add(ChatMessage.bot(reply));
      _waitingReply = false;
    });
    _scrollToBottom();
  }

  Future<String> _fakeBotReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'You said: "$userText"';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Asistan'),
        elevation: 0,
      ),
      body: GestureDetector(
        // Boş alana dokununca klavyeyi kapat
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // MESAJ LİSTESİ
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 8),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final prev = index > 0 ? _messages[index - 1] : null;
                    final showHeader = msg.sender == Sender.bot &&
                        (prev == null || prev.sender != Sender.bot);

                    return ChatBubble(
                      message: msg,
                      showHeader: showHeader,
                    );
                  },
                ),
              ),

              if (_waitingReply)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: _TypingIndicator(),
                ),

              // MESAJ GİRİŞ ALANI
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
      children: [
        const SizedBox(width: 18),
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
          child: const Text('typing...'),
        ),
      ],
    );
  }
}
