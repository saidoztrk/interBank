// lib/models/session_info.dart
class SessionInfo {
  final String id;
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? messageCount;
  final String? lastMessage;

  const SessionInfo({
    required this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.messageCount,
    this.lastMessage,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] ?? json['session_id'] ?? '',
      title: json['title'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      messageCount: json['message_count'],
      lastMessage: json['last_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'message_count': messageCount,
      'last_message': lastMessage,
    };
  }

  @override
  String toString() {
    return 'SessionInfo(id: $id, title: $title, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
