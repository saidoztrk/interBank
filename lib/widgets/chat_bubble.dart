import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'chat_bot_badge.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  bool get isBot => message.sender == Sender.bot;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: isBot ? const Color(0xFFF2F4F7) : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isBot ? Colors.black87 : Colors.white,
          height: 1.25,
        ),
      ),
    );

    if (!isBot) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // rozet büyüdüğü için hafif boşluk arttırdık
            padding: const EdgeInsets.only(right: 10, top: 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              // 28 → 42 (1.5x)
              child: ChatBotBadge(state: message.badgeState, size: 42),
            ),
          ),
          bubble,
        ],
      ),
    );
  }
}
