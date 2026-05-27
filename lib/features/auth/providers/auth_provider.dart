import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  User? _user;
  String? _username;
  String? _pendingUsername;

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
        _username = data['username'];
      } else {
        final name = _pendingUsername ?? (_user?.email?.split('@').first ?? 'User');
        await Supabase.instance.client.from('users').insert({
          'id': uid,
          'username': name,
          'email': _user?.email ?? '',
        });
        _username = name;
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
        final results = await Supabase.instance.client
            .rpc('get_email_by_username', params: {'p_username': usernameOrEmail});
        if (results == null || (results as List).isEmpty) return 'User not found';
        email = (results[0] as Map)['email'] as String;
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

      _pendingUsername = username;
      await _auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      _pendingUsername = null;
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
