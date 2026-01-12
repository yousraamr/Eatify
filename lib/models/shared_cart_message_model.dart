class SharedCartMessage {
  final String id;
  final String cartId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final String type; // 'user' or 'system'
  // extra
  final String? username;
  final int? userNumber;
  final Set<String> seenBy;
  SharedCartMessage({
    required this.id,
    required this.cartId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.type,
    this.username,
    this.userNumber,
    Set<String>? seenBy,
  }) : seenBy = seenBy ?? {};

  factory SharedCartMessage.fromMap(Map<String, dynamic> map) {
    return SharedCartMessage(
      id: map['id'],
      cartId: map['cart_id'],
      senderId: map['sender_id'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
      username: map['username'],
      userNumber: map['user_number'],
      type : map['type'] ?? 'user',
      seenBy: {},
    );
  }

  SharedCartMessage copyWith({
    String? username,
    int? userNumber,
    Set<String>? seenBy,
  }) {
    return SharedCartMessage(
      id: id,
      cartId: cartId,
      senderId: senderId,
      message: message,
      createdAt: createdAt,
      username: username ?? this.username,
      userNumber: userNumber ?? this.userNumber,
      type: type,
      seenBy: seenBy ?? this.seenBy,
    );
  }
}
