class PrivateMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isSeen;
  PrivateMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isSeen,
  });

  factory PrivateMessage.fromMap(Map<String, dynamic> map) {
    return PrivateMessage(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
      isSeen: map['is_seen'] ?? false,
    );
  }
}
