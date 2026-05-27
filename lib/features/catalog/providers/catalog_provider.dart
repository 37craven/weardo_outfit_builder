import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

class CatalogProvider extends ChangeNotifier {
  List<ClothingItem> _allClothes = [];
  bool _isLoading = true;
  bool _isMutating = false;
  bool _hasError = false;
  String? _userId;
  StreamSubscription? _authSub;

  List<ClothingItem> get allClothes => _allClothes;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get hasError => _hasError;

  List<ClothingItem> getHeadwear() {
    return _allClothes.where((c) => c.category == 'Headwear').toList();
  }

  List<ClothingItem> getOuterTops() {
    return _allClothes.where((c) => c.category == 'Outer Tops').toList();
  }

  List<ClothingItem> getInnerTops() {
    return _allClothes.where((c) => c.category == 'Inner Tops').toList();
  }

  List<ClothingItem> getBottoms() {
    return _allClothes.where((c) => c.category == 'Bottoms').toList();
  }

  List<ClothingItem> getFootwear() {
    return _allClothes.where((c) => c.category == 'Footwear').toList();
  }

  List<ClothingItem> getOuter() => getOuterTops();
  List<ClothingItem> getInner() => getInnerTops();
  List<ClothingItem> getPants() => getBottoms();
  List<ClothingItem> getShoes() => getFootwear();

  List<ClothingItem> getFavoriteItems() {
    return _allClothes.where((c) => c.isFavorited).toList();
  }

  int getItemCount() => _allClothes.length;

  CatalogProvider() {
    _init();
  }

  void _init() {
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _fetchClothes();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _userId = event.session?.user.id;
      if (event.session != null) {
        _allClothes = [];
        _isLoading = true;
        notifyListeners();
        _fetchClothes();
      } else {
        _allClothes = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchClothes() async {
    final uid = _userId;
    if (uid == null) return;
    _hasError = false;
    try {
      final data = await Supabase.instance.client
          .from('clothes')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      _allClothes = (data as List)
          .map((row) => ClothingItem.fromMap(row['id'], row))
          .toList();
      _isLoading = false;
    } catch (_) {
      _isLoading = false;
      _hasError = true;
    }
    notifyListeners();
  }

  void retry() {
    if (!_hasError) return;
    _fetchClothes();
  }

  Future<void> addClothingItem(ClothingItem item) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('clothes').insert(item.toMap());
      await _fetchClothes();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<int> getSavedOutfitCountForItem(String itemId) async {
    final uid = _userId;
    if (uid == null) return 0;
    try {
      final data = await Supabase.instance.client
          .from('favorites')
          .select('id')
          .or('headwear_id.eq.$itemId,outer_id.eq.$itemId,inner_id.eq.$itemId,pants_id.eq.$itemId,shoes_id.eq.$itemId')
          .eq('user_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> removeClothingItem(String id) async {
    final count = await getSavedOutfitCountForItem(id);
    if (count > 0) {
      throw Exception('USED_IN_SAVED_OUTFITS:$count');
    }
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('clothes').delete().eq('id', id);
      await _fetchClothes();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteItem(String id) async {
    final itemIndex = _allClothes.indexWhere((c) => c.id == id);
    if (itemIndex == -1) return;
    final newValue = !_allClothes[itemIndex].isFavorited;
    _allClothes[itemIndex] = _allClothes[itemIndex].copyWith(isFavorited: newValue);
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('clothes')
          .update({'is_favorited': newValue})
          .eq('id', id);
    } catch (_) {
      _allClothes[itemIndex] = _allClothes[itemIndex].copyWith(isFavorited: !newValue);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
