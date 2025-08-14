import 'package:flutter/material.dart';
import '../models/bot_badge_state.dart';

class ChatBotBadge extends StatelessWidget {
  const ChatBotBadge(
      {super.key, required this.state, this.size = 28}); // 22 -> 28
  final BotBadgeState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String wanted = state.asset;
    const String fallback = 'lib/assets/images/chatbot/tele_sekreter.png';

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        wanted,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Image.asset(fallback, fit: BoxFit.contain),
      ),
    );
  }
}
