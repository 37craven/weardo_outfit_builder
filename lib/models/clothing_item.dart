class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final double heightInches;
  final double widthInches;
  final String category;
  final DateTime createdAt;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.heightInches,
    required this.widthInches,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'height_inches': heightInches,
      'width_inches': widthInches,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ClothingItem.fromMap(String id, Map<String, dynamic> map) {
    return ClothingItem(
      id: id,
      userId: map['user_id'],
      imageUrl: map['image_url'],
      heightInches: (map['height_inches'] as num).toDouble(),
      widthInches: (map['width_inches'] as num).toDouble(),
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
