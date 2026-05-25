import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

class CatalogProvider extends ChangeNotifier {
  List<ClothingItem> _allClothes = [];
  bool _isLoading = false;

  List<ClothingItem> get allClothes => _allClothes;
  bool get isLoading => _isLoading;

  List<ClothingItem> getOuter() {
    return _allClothes.where((c) => c.category == 'Outer').toList();
  }

  List<ClothingItem> getInner() {
    return _allClothes.where((c) => c.category == 'Inner').toList();
  }

  List<ClothingItem> getPants() {
    return _allClothes.where((c) => c.category == 'Pants').toList();
  }

  List<ClothingItem> getShoes() {
    return _allClothes.where((c) => c.category == 'Shoes').toList();
  }

  List<ClothingItem> getFavoriteItems() {
    return _allClothes.where((c) => c.isFavorited).toList();
  }

  int getItemCount() => _allClothes.length;

  Future<void> fetchUserClothes() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final data = await Supabase.instance.client
        .from('clothes')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    _allClothes = (data as List)
        .map((row) => ClothingItem.fromMap(row['id'], row))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addClothingItem(ClothingItem item) async {
    await Supabase.instance.client
        .from('clothes')
        .insert(item.toMap());
    await fetchUserClothes();
  }

  Future<void> removeClothingItem(String id) async {
    await Supabase.instance.client
        .from('clothes')
        .delete()
        .eq('id', id);
    await fetchUserClothes();
  }

  Future<void> toggleFavoriteItem(String id) async {
    final item = _allClothes.firstWhere((c) => c.id == id);
    final newValue = !item.isFavorited;
    await Supabase.instance.client
        .from('clothes')
        .update({'is_favorited': newValue})
        .eq('id', id);
    _allClothes = _allClothes.map((c) {
      return c.id == id ? c.copyWith(isFavorited: newValue) : c;
    }).toList();
    notifyListeners();
  }
}
