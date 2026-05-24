class FavoriteOutfit {
  final String id;
  final String userId;
  final String? outerId;
  final String innerId;
  final String pantsId;
  final String shoesId;
  final DateTime savedAt;

  FavoriteOutfit({
    required this.id,
    required this.userId,
    this.outerId,
    required this.innerId,
    required this.pantsId,
    required this.shoesId,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'outer_id': outerId,
      'inner_id': innerId,
      'pants_id': pantsId,
      'shoes_id': shoesId,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory FavoriteOutfit.fromMap(String id, Map<String, dynamic> map) {
    return FavoriteOutfit(
      id: id,
      userId: map['user_id'],
      outerId: map['outer_id'],
      innerId: map['inner_id'],
      pantsId: map['pants_id'],
      shoesId: map['shoes_id'],
      savedAt: DateTime.parse(map['saved_at']),
    );
  }
}
