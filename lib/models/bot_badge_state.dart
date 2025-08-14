// lib/models/bot_badge_state.dart

enum BotBadgeState {
  teleSekreter, // default
  thinking, // düşünürken
  error, // ağ/işlem hatası
}

extension BotBadgeAsset on BotBadgeState {
  String get asset {
    switch (this) {
      case BotBadgeState.thinking:
        return 'lib/assets/images/chatbot/thinking.png';
      case BotBadgeState.error:
        return 'lib/assets/images/chatbot/404_hata.png';
      case BotBadgeState.teleSekreter:
      default:
        return 'lib/assets/images/chatbot/tele_sekreter.png';
    }
  }
}
