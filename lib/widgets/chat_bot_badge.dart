// lib/widgets/chat_bot_badge.dart
import 'package:flutter/material.dart';
import '../models/bot_badge_state.dart';

class ChatBotBadge extends StatelessWidget {
  final BotBadgeState state;
  final double size;

  const ChatBotBadge({
    super.key,
    required this.state,
    this.size = 42, // varsayılan 42 (1.5x büyütme için ideal)
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      state.asset, // enum extension’dan geliyor
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
