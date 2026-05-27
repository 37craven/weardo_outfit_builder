import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

class CatalogProvider extends ChangeNotifier {
  List<ClothingItem> _allClothes = [];
  bool _isLoading = true;
  bool _isMutating = false;
  bool _hasError = false;
  StreamSubscription? _streamSub;
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
    _setupStream();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _allClothes = [];
        _isLoading = true;
        notifyListeners();
        _setupStream();
      } else {
        _streamSub?.cancel();
        _allClothes = [];
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
        .from('clothes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          _allClothes = (data as List)
              .map((row) => ClothingItem.fromMap(row['id'], row))
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

  Future<void> addClothingItem(ClothingItem item) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('clothes').insert(item.toMap());
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> removeClothingItem(String id) async {
    _isMutating = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('clothes').delete().eq('id', id);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteItem(String id) async {
    final item = _allClothes.firstWhere((c) => c.id == id);
    final newValue = !item.isFavorited;
    _allClothes = _allClothes.map((c) {
      return c.id == id ? c.copyWith(isFavorited: newValue) : c;
    }).toList();
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('clothes')
          .update({'is_favorited': newValue})
          .eq('id', id);
    } catch (_) {
      _allClothes = _allClothes.map((c) {
        return c.id == id ? c.copyWith(isFavorited: !newValue) : c;
      }).toList();
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
