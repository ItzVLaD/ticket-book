import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _user;

  User? get user => _user;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (_user != null) {
        _userService.createOrUpdateUser(_user!);
      }
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  bool get isAuthenticated => _user != null;
}
