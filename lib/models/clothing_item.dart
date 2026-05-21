class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final double heightInches;
  final double widthInches;
  final String category; // 'Shirt', 'Pants', 'Shoes'
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
      'userId': userId,
      'imageUrl': imageUrl,
      'heightInches': heightInches,
      'widthInches': widthInches,
      'category': category,
      'createdAt': createdAt,
    };
  }

  factory ClothingItem.fromMap(String id, Map<String, dynamic> map) {
    return ClothingItem(
      id: id,
      userId: map['userId'],
      imageUrl: map['imageUrl'],
      heightInches: (map['heightInches'] as num).toDouble(),
      widthInches: (map['widthInches'] as num).toDouble(),
      category: map['category'],
      createdAt: (map['createdAt'] as DateTime),
    );
  }
}