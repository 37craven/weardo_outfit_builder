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
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) _fetchUserData(user.uid);
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    _username = doc['username'];
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
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'username': username,
        'email': email,
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