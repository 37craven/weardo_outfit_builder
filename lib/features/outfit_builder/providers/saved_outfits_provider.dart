import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';

class SavedOutfitsProvider extends ChangeNotifier {
  List<FavoriteOutfit> _savedOutfits = [];
  bool _isLoading = true;
  bool _isMutating = false;
  bool _hasError = false;
  FavoriteOutfit? _pendingLoad;
  String? _userId;
  StreamSubscription? _authSub;

  List<FavoriteOutfit> get savedOutfits => _savedOutfits;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get hasError => _hasError;
  FavoriteOutfit? get pendingLoad => _pendingLoad;

  void requestLoad(FavoriteOutfit outfit) {
    _pendingLoad = outfit;
    notifyListeners();
  }

  void clearPendingLoad() {
    _pendingLoad = null;
  }

  SavedOutfitsProvider() {
    _init();
  }

  void _init() {
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _fetchSavedOutfits();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _userId = event.session?.user.id;
      if (event.session != null) {
        _savedOutfits = [];
        _isLoading = true;
        notifyListeners();
        _fetchSavedOutfits();
      } else {
        _savedOutfits = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchSavedOutfits() async {
    final uid = _userId;
    if (uid == null) return;
    _hasError = false;
    try {
      final data = await Supabase.instance.client
          .from('favorites')
          .select()
          .eq('user_id', uid)
          .order('saved_at', ascending: false);
      _savedOutfits = (data as List)
          .map((row) => FavoriteOutfit.fromMap(row['id'], row))
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
    _fetchSavedOutfits();
  }

  Future<void> addSavedOutfit(FavoriteOutfit outfit) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('favorites').insert(outfit.toMap());
      await _fetchSavedOutfits();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> removeSavedOutfit(String id) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('favorites').delete().eq('id', id);
      await _fetchSavedOutfits();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
