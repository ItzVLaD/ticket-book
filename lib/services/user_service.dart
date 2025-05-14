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
}
