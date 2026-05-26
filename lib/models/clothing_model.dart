class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final double heightInches;
  final double widthInches;
  final String category;
  final String name;
  final DateTime createdAt;
  final bool isFavorited;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.heightInches,
    required this.widthInches,
    required this.category,
    required this.name,
    required this.createdAt,
    this.isFavorited = false,
  });

  ClothingItem copyWith({bool? isFavorited}) {
    return ClothingItem(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      heightInches: heightInches,
      widthInches: widthInches,
      category: category,
      name: name,
      createdAt: createdAt,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'height_inches': heightInches,
      'width_inches': widthInches,
      'category': category,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_favorited': isFavorited,
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
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      isFavorited: map['is_favorited'] ?? false,
    );
  }
}
