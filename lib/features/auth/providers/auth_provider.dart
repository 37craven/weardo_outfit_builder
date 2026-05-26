import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  User? _user;
  String? _username;

  User? get currentUser => _user;
  String? get username => _username;

  AuthProvider() {
    _auth.onAuthStateChange.listen((event) async {
      _user = event.session?.user;
      if (_user != null) {
        await _fetchUserData(_user!.id);
      } else {
        _username = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        _username = data['username'] ?? 'User';
      } else {
        final email = _user?.email ?? '';
        final defaultUsername = email.split('@').first;
        await Supabase.instance.client.from('users').insert({
          'id': uid,
          'username': defaultUsername,
          'email': email,
        });
        _username = defaultUsername;
      }
    } catch (e) {
      _username = 'User';
    }
    notifyListeners();
  }

  Future<String?> login(String usernameOrEmail, String password) async {
    try {
      String email;
      if (usernameOrEmail.contains('@')) {
        email = usernameOrEmail;
      } else {
        final result = await Supabase.instance.client
            .from('users')
            .select('email')
            .eq('username', usernameOrEmail)
            .maybeSingle();
        if (result == null) return 'User not found';
        email = result['email'] as String;
      }
      await _auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> register(String email, String username, String password) async {
    try {
      final existing = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (existing != null) return 'Username already taken';

      final response = await _auth.signUp(email: email, password: password);
      final user = response.user;
      if (user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'username': username,
          'email': email,
        });
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
