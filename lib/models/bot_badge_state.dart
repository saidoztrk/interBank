// lib/models/bot_badge_state.dart

enum BotBadgeState {
  normal, // captain.png
  thinking, // captain_thinking.png
  writing, // captain_writing.png
  connection, // captain_connection.png
  noConnection, // captain_noconnection.png
  sekreter, // captain_sekreter.png
}

extension BotBadgeAsset on BotBadgeState {
  String get asset {
    switch (this) {
      case BotBadgeState.thinking:
        return 'lib/assets/images/captain/captain_thinking.png';
      case BotBadgeState.writing:
        return 'lib/assets/images/captain/captain_writing.png';
      case BotBadgeState.connection:
        return 'lib/assets/images/captain/captain_connection.png';
      case BotBadgeState.noConnection:
        return 'lib/assets/images/captain/captain_noconnection.png';
      case BotBadgeState.sekreter:
        return 'lib/assets/images/captain/captain_sekreter.png';
      case BotBadgeState.normal:
      default:
        return 'lib/assets/images/captain/captain.png';
    }
  }
}
