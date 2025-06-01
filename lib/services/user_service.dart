import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createOrUpdateUser(User user) async {
    final docRef = usersCollection.doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'wishlist': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
      }, SetOptions(merge: true));
    }
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return usersCollection.doc(uid).get();
  }

  Future<void> addToWishlist(String userId, String eventId) async {
    try {
      await usersCollection.doc(userId).update({
        'wishlist': FieldValue.arrayUnion([eventId]),
      });
    } catch (e) {
      // If document doesn't exist, create it with the wishlist
      await usersCollection.doc(userId).set({
        'wishlist': [eventId],
      }, SetOptions(merge: true));
    }
  }

  Future<void> removeFromWishlist(String userId, String eventId) async {
    try {
      await usersCollection.doc(userId).update({
        'wishlist': FieldValue.arrayRemove([eventId]),
      });
    } catch (e) {
      // If document doesn't exist, ignore the operation
      // since there's nothing to remove
    }
  }

  Future<List<String>> getWishlist(String userId) async {
    final snapshot = await usersCollection.doc(userId).get();

    // Check if document exists
    if (!snapshot.exists) {
      return <String>[];
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('wishlist') || data['wishlist'] == null) {
      return <String>[];
    }

    final wishlist = data['wishlist'] as List<dynamic>;
    return wishlist.cast<String>();
  }

  // Delete all user data from Firestore
  Future<void> deleteUserData(String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    // Delete user document
    batch.delete(usersCollection.doc(userId));

    // Delete all user bookings
    final bookingsQuery =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .get();

    for (var doc in bookingsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Execute batch delete
    await batch.commit();
  }
}
