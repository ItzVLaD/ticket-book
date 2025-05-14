import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createOrUpdateUser(User user) async {
    return usersCollection.doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'wishlist': [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return usersCollection.doc(uid).get();
  }

  Future<void> addToWishlist(String userId, String eventId) async {
    await usersCollection.doc(userId).update({
      'wishlist': FieldValue.arrayUnion([eventId]),
    });
  }

  Future<void> removeFromWishlist(String userId, String eventId) async {
    await usersCollection.doc(userId).update({
      'wishlist': FieldValue.arrayRemove([eventId]),
    });
  }

  Future<List<String>> getWishlist(String userId) async {
    final snapshot = await usersCollection.doc(userId).get();
    final wishlist = snapshot['wishlist'] as List<dynamic>;
    return wishlist.cast<String>();
  }
}
