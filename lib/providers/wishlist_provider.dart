import 'package:flutter/material.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/services/user_service.dart';

class WishlistProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthProvider _authProvider;

  WishlistProvider(this._authProvider);

  List<String> _wishlist = [];

  List<String> get wishlist => _wishlist;

  Future<void> loadWishlist() async {
    final userId = _authProvider.user?.uid;
    if (userId != null) {
      _wishlist = await _userService.getWishlist(userId);
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(String eventId) async {
    final userId = _authProvider.user?.uid;
    if (userId == null) return;

    if (_wishlist.contains(eventId)) {
      await _userService.removeFromWishlist(userId, eventId);
      _wishlist.remove(eventId);
    } else {
      await _userService.addToWishlist(userId, eventId);
      _wishlist.add(eventId);
    }
    notifyListeners();
  }

  bool isInWishlist(String eventId) => _wishlist.contains(eventId);
}
