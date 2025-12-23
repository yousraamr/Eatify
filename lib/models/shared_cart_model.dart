class SharedCart {
  final String id;
  final String code;
  final String ownerId;
  final String restaurantId;
  final bool isActive;

  SharedCart({
    required this.id,
    required this.code,
    required this.ownerId,
    required this.restaurantId,
    required this.isActive,
  });

  factory SharedCart.fromMap(Map<String, dynamic> map) {
    return SharedCart(
      id: map['id'],
      code: map['code'],
      ownerId: map['owner_id'],
      restaurantId: map['restaurant_id'],
      isActive: map['is_active'],
    );
  }
}
