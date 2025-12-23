class SharedCartItem {
  final String id;
  final String userId;
  final String userName;
  final String menuItemName;
  final double price;
  final int quantity;

  SharedCartItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.menuItemName,
    required this.price,
    required this.quantity,
  });

  factory SharedCartItem.fromMap(Map<String, dynamic> map) {
    return SharedCartItem(
      id: map['id'],
      userId: map['user_id'],
      userName: map['auth.users']?['profiles']?['full_name'] ?? 'User',
      menuItemName: map['menu_items']['name'],
      price: (map['menu_items']['price'] as num).toDouble(),
      quantity: map['quantity'],
    );
  }

  double get totalPrice => price * quantity;
}
