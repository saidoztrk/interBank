// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'chat_bot_badge.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  bool get isBot => message.sender == Sender.bot;

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.70;

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color:
              isBot ? const Color(0xFFF2F4F7) : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.left,
          softWrap: true,
          style: TextStyle(
            color: isBot ? Colors.black87 : Colors.white,
            height: 1.25,
            fontSize: 15,
          ),
        ),
      ),
    );

    // Kullanıcı mesajı: sağda, avatar yok
    if (!isBot) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }

    // Bot mesajı: solda, kaptan rozeti + balon
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kaptan rozeti
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: ChatBotBadge(
                state: message.badgeState, // ChatMessage.badgeState bekleniyor
              ),
            ),
          ),
          // Mesaj balonu
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
