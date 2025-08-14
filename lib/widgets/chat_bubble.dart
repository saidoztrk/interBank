// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final bool isUser = message.sender == Sender.user;
    final Color bubbleColor =
        isUser ? Colors.blue.shade600 : Colors.grey.shade200;
    final Color textColor = isUser ? Colors.white : Colors.black87;
    final Alignment alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;

    final BorderRadius borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    // Zaman damgası güvenli şekilde hazırlanıyor
    final String timeText = DateFormat.Hm().format(message.createdAt);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
              ),
            ),
            if (isUser)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
