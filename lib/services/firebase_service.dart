import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Helper: get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  // Helper: check if user is logged in
  bool get isLoggedIn => auth.currentUser != null;

  // Helper: sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  // User collection reference
  CollectionReference get usersCollection => firestore.collection('users');

  // Clothes collection reference
  CollectionReference get clothesCollection => firestore.collection('clothes');

  // Favorites collection reference
  CollectionReference get favoritesCollection => firestore.collection('favorites');

  // Storage reference for clothes images
  Reference getClothesStorageRef(String userId, String fileName) {
    return storage.ref().child('clothes/$userId/$fileName');
  }
}