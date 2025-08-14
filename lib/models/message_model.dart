// lib/models/message_model.dart
import 'package:uuid/uuid.dart';
import 'bot_badge_state.dart';

enum Sender { user, bot }

final _uuid = const Uuid();

/// Sohbet mesajı modeli
class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime createdAt;
  final BotBadgeState badgeState;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.badgeState = BotBadgeState.teleSekreter, // <— default: teleSekreter
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Kullanıcı mesajı oluşturucu
  factory ChatMessage.user(String text) => ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: Sender.user,
      );

  /// Bot mesajı oluşturucu — varsayılan rozet tele_sekreter
  factory ChatMessage.bot(
    String text, {
    BotBadgeState badge = BotBadgeState.teleSekreter, // <— burada da default
  }) =>
      ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: Sender.bot,
        badgeState: badge,
      );

  ChatMessage copyWith({
    String? id,
    String? text,
    Sender? sender,
    DateTime? createdAt,
    BotBadgeState? badgeState,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      badgeState: badgeState ?? this.badgeState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.name, // 'user' / 'bot'
        'badgeState': badgeState.name, // 'teleSekreter' / 'thinking' / 'error'
        'createdAt': createdAt.toIso8601String(),
      };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    final senderStr = (json['sender'] as String?)?.toLowerCase();
    final sender = senderStr == 'user' ? Sender.user : Sender.bot;

    final badgeStr = (json['badgeState'] as String?) ?? 'teleSekreter';
    final badge = BotBadgeState.values.firstWhere(
      (e) => e.name == badgeStr,
      orElse: () => BotBadgeState.teleSekreter,
    );

    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: sender,
      badgeState: badge,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
