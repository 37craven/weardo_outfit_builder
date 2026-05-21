import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weardo_outfit_builder/models/favorite_outfit.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FavoriteOutfit> _favorites = [];
  bool _isLoading = false;

  List<FavoriteOutfit> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final query = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .get();

    _favorites = query.docs.map((doc) => FavoriteOutfit.fromMap(doc.id, doc.data())).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFavorite(FavoriteOutfit outfit) async {
    await _firestore.collection('favorites').doc(outfit.id).set(outfit.toMap());
    await fetchFavorites();
  }

  Future<void> removeFavorite(String id) async {
    await _firestore.collection('favorites').doc(id).delete();
    await fetchFavorites();
  }
}