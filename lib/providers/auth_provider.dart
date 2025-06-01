import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/booking_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (_user != null) {
        await _userService.createOrUpdateUser(_user!);
        // Clean up expired bookings when user signs in
        await _bookingService.removeExpiredBookings(_user!.uid);
      }
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) {
      throw Exception('No user is currently signed in');
    }

    _setLoading(true);
    try {
      final userId = _user!.uid;

      // First try to delete the Firebase Auth account
      // This will handle re-authentication if needed
      await _authService.deleteAccount();

      // Only delete Firestore data after successful auth account deletion
      await _userService.deleteUserData(userId);

      // User state will be automatically updated through auth state changes
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> switchAccount() async {
    _setLoading(true);
    try {
      await _authService.switchAccount();
      // User state will be automatically updated through auth state changes
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool get isAuthenticated => _user != null;
}
