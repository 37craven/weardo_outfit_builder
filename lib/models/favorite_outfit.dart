class FavoriteOutfit {
  final String id;
  final String userId;
  final String shirtId;
  final String pantsId;
  final String shoesId;
  final DateTime savedAt;

  FavoriteOutfit({
    required this.id,
    required this.userId,
    required this.shirtId,
    required this.pantsId,
    required this.shoesId,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'shirt_id': shirtId,
      'pants_id': pantsId,
      'shoes_id': shoesId,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory FavoriteOutfit.fromMap(String id, Map<String, dynamic> map) {
    return FavoriteOutfit(
      id: id,
      userId: map['user_id'],
      shirtId: map['shirt_id'],
      pantsId: map['pants_id'],
      shoesId: map['shoes_id'],
      savedAt: DateTime.parse(map['saved_at']),
    );
  }
}
