import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';

class FavoriteProvider extends ChangeNotifier {
  List<FavoriteOutfit> _favorites = [];
  bool _isLoading = false;

  List<FavoriteOutfit> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final data = await Supabase.instance.client
        .from('favorites')
        .select('*')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    _favorites = (data as List)
        .map((row) => FavoriteOutfit.fromMap(row['id'], row))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFavorite(FavoriteOutfit outfit) async {
    await Supabase.instance.client
        .from('favorites')
        .insert(outfit.toMap());
    await fetchFavorites();
  }

  Future<void> removeFavorite(String id) async {
    await Supabase.instance.client
        .from('favorites')
        .delete()
        .eq('id', id);
    await fetchFavorites();
  }
}
