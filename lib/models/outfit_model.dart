class FavoriteOutfit {
  final String id;
  final String userId;
  final String? headwearId;
  final String? outerId;
  final String innerId;
  final String pantsId;
  final String shoesId;
  final DateTime savedAt;

  FavoriteOutfit({
    required this.id,
    required this.userId,
    this.headwearId,
    this.outerId,
    required this.innerId,
    required this.pantsId,
    required this.shoesId,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'outer_id': outerId,
      'inner_id': innerId,
      'pants_id': pantsId,
      'shoes_id': shoesId,
      'saved_at': savedAt.toIso8601String(),
    };
    if (headwearId != null) map['headwear_id'] = headwearId;
    return map;
  }

  factory FavoriteOutfit.fromMap(String id, Map<String, dynamic> map) {
    return FavoriteOutfit(
      id: id,
      userId: map['user_id'],
      headwearId: map['headwear_id'],
      outerId: map['outer_id'],
      innerId: map['inner_id'],
      pantsId: map['pants_id'],
      shoesId: map['shoes_id'],
      savedAt: DateTime.parse(map['saved_at']),
    );
  }
}
