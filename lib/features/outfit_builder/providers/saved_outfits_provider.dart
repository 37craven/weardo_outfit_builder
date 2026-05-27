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
  StreamSubscription? _streamSub;
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
    _setupStream();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _savedOutfits = [];
        _isLoading = true;
        notifyListeners();
        _setupStream();
      } else {
        _streamSub?.cancel();
        _savedOutfits = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _setupStream() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _streamSub?.cancel();
    _hasError = false;
    _streamSub = Supabase.instance.client
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('saved_at', ascending: false)
        .listen((data) {
          _savedOutfits = (data as List)
              .map((row) => FavoriteOutfit.fromMap(row['id'], row))
              .toList();
          _isLoading = false;
          _hasError = false;
          notifyListeners();
        }, onError: (_) {
          _isLoading = false;
          _hasError = true;
          notifyListeners();
        });
  }

  void retry() {
    if (!_hasError) return;
    _setupStream();
  }

  Future<void> addSavedOutfit(FavoriteOutfit outfit) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('favorites').insert(outfit.toMap());
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
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
