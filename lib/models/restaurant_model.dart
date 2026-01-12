class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final double latitude;
  final double longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) {
  return Restaurant(
    id: map['id'].toString(),
    name: map['name'] ?? 'No Name',
    imageUrl: map['image_url'] ?? '',
    rating: map['rating'] != null ? double.parse(map['rating'].toString()) : 0.0,
    latitude: map['latitude'] != null ? double.parse(map['latitude'].toString()) : 0.0,
    longitude: map['longitude'] != null ? double.parse(map['longitude'].toString()) : 0.0,
  );
}
}