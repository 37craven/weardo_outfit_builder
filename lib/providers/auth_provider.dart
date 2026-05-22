import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _username;

  User? get currentUser => _user;
  String? get username => _username;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData(user.uid);
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _username = doc['username'] ?? 'User';
      } else {
        // If the document doesn't exist, create it now
        final email = _user?.email ?? '';
        final defaultUsername = email.split('@').first;
        await _firestore.collection('users').doc(uid).set({
          'username': defaultUsername,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _username = defaultUsername;
        debugPrint('Created missing user document for uid: $uid');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _username = 'User';
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> register(String email, String username, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create user document in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}