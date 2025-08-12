import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.showHeader = false,
  });

  final ChatMessage message;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final isBot = message.sender == Sender.bot;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isBot ? Colors.grey.shade200 : Colors.blue.shade600,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isBot ? 4 : 16),
          bottomRight: Radius.circular(isBot ? 16 : 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isBot ? Colors.black87 : Colors.white,
          fontSize: 15,
        ),
      ),
    );

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: isBot ? Colors.grey.shade300 : Colors.blue.shade100,
      child: Icon(
        isBot ? Icons.smart_toy : Icons.person,
        size: 18,
        color: isBot ? Colors.black54 : Colors.blue.shade800,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (showHeader && isBot)
            Container(
              margin: const EdgeInsets.only(left: 34, bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'chatbot',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: isBot
                ? [
                    avatar,
                    const SizedBox(width: 8),
                    Flexible(child: bubble),
                    const Spacer(),
                  ]
                : [
                    const Spacer(),
                    Flexible(child: bubble),
                    const SizedBox(width: 8),
                    avatar,
                  ],
          ),
        ],
      ),
    );
  }
}
