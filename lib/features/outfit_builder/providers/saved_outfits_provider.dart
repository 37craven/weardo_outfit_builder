import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';

class SavedOutfitsProvider extends ChangeNotifier {
  List<FavoriteOutfit> _savedOutfits = [];
  bool _isLoading = false;
  FavoriteOutfit? _pendingLoad;

  List<FavoriteOutfit> get savedOutfits => _savedOutfits;
  bool get isLoading => _isLoading;
  FavoriteOutfit? get pendingLoad => _pendingLoad;

  void requestLoad(FavoriteOutfit outfit) {
    _pendingLoad = outfit;
    notifyListeners();
  }

  void clearPendingLoad() {
    _pendingLoad = null;
  }

  Future<void> fetchSavedOutfits() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final data = await Supabase.instance.client
        .from('favorites')
        .select('*')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    _savedOutfits = (data as List)
        .map((row) => FavoriteOutfit.fromMap(row['id'], row))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSavedOutfit(FavoriteOutfit outfit) async {
    await Supabase.instance.client
        .from('favorites')
        .insert(outfit.toMap());
    await fetchSavedOutfits();
  }

  Future<void> removeSavedOutfit(String id) async {
    await Supabase.instance.client
        .from('favorites')
        .delete()
        .eq('id', id);
    await fetchSavedOutfits();
  }
}
