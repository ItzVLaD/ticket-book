import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Вхід через Google
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  // Вихід
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Delete account completely
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Sign out from Google first
    await _googleSignIn.signOut();

    // Delete the Firebase Auth account
    await user.delete();
  }

  // Switch account (sign out and trigger new sign in)
  Future<User?> switchAccount() async {
    // Sign out from current account
    await signOut();

    // Trigger new Google sign in
    return await signInWithGoogle();
  }

  // Поточний користувач
  User? get currentUser => _auth.currentUser;

  // Стрім авторизації
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
