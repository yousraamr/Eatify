class MenuItem {
  final String id;
  final String name;
  final double price;
  final String restaurantId;
  final String restaurantName; //new
  final String description;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.restaurantId,
    required this.restaurantName, //new
    required this.description,
    required this.imageUrl,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      restaurantName: map['restaurant_name'] ?? 'Unknown Restaurant',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] ?? '',
    );
  }
}
