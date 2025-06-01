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

  // Re-authenticate user with Google (required for sensitive operations)
  Future<void> reauthenticateWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Re-authentication cancelled by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Re-authenticate the user
    await user.reauthenticateWithCredential(credential);
  }

  // Delete account completely with re-authentication
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      // Try to delete the account directly first
      await user.delete();
    } catch (e) {
      // If it fails due to recent login requirement, re-authenticate and try again
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Re-authenticate with Google
        await reauthenticateWithGoogle();
        
        // Try deleting again after re-authentication
        await user.delete();
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
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
