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
      'userId': userId,
      'shirtId': shirtId,
      'pantsId': pantsId,
      'shoesId': shoesId,
      'savedAt': savedAt,
    };
  }

  factory FavoriteOutfit.fromMap(String id, Map<String, dynamic> map) {
    return FavoriteOutfit(
      id: id,
      userId: map['userId'],
      shirtId: map['shirtId'],
      pantsId: map['pantsId'],
      shoesId: map['shoesId'],
      savedAt: (map['savedAt'] as DateTime),
    );
  }
}