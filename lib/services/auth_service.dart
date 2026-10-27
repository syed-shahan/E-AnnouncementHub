import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() => _auth.signOut();

  static User? currentUser() => _auth.currentUser;

  /// returns true if user is admin (custom claim or email fallback)
  static Future<bool> checkIsAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final idToken = await user.getIdTokenResult(forceRefresh);
    final claims = idToken.claims ?? {};
    if (claims['isAdmin'] == true) return true;
    final email = user.email?.toLowerCase();
    if (email == 'hydershahan2@gmail.com') return true; // fallback for debugging
    return false;
  }

  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
