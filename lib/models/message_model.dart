// lib/models/message_model.dart
import 'package:uuid/uuid.dart';

enum Sender { user, bot }

final _uuid = Uuid();

class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Kullanıcı mesajı oluşturucu
  factory ChatMessage.user(String text) => ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: Sender.user,
      );

  /// Bot mesajı oluşturucu
  factory ChatMessage.bot(String text) => ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: Sender.bot,
      );

  ChatMessage copyWith({
    String? id,
    String? text,
    Sender? sender,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.name, // 'user' / 'bot'
        'createdAt': createdAt.toIso8601String(),
      };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    final senderStr = (json['sender'] as String?)?.toLowerCase();
    final sender = senderStr == 'user' ? Sender.user : Sender.bot;

    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: sender,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
