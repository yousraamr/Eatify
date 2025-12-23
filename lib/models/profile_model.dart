class Profile {
  final String id;
  final String fullName;
  final String? phone;

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'] ?? 'User',
      phone: map['phone'],
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : 'User';
}