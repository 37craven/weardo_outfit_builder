import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weardo_outfit_builder/models/clothing_item.dart';

class ClothesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ClothingItem> _allClothes = [];
  bool _isLoading = false;

  List<ClothingItem> get allClothes => _allClothes;
  bool get isLoading => _isLoading;

  List<ClothingItem> getShirts() {
    return _allClothes.where((c) => c.category == 'Shirt').toList();
  }

  List<ClothingItem> getPants() {
    return _allClothes.where((c) => c.category == 'Pants').toList();
  }

  List<ClothingItem> getShoes() {
    return _allClothes.where((c) => c.category == 'Shoes').toList();
  }

  int getItemCount() => _allClothes.length;

  // Make this async and return Future
  Future<void> fetchUserClothes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final query = await _firestore
        .collection('clothes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    _allClothes = query.docs.map((doc) => ClothingItem.fromMap(doc.id, doc.data())).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addClothingItem(ClothingItem item) async {
    await _firestore.collection('clothes').doc(item.id).set(item.toMap());
    await fetchUserClothes(); // refresh after add
  }

  Future<void> removeClothingItem(String id) async {
    await _firestore.collection('clothes').doc(id).delete();
    await fetchUserClothes();
  }
}