// lib/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Ваш FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn з явним clientId для web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '645034820770-08i24pd0cragdlnht64nrlpahdujck32.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Вхід через Google
  Future<User?> signInWithGoogle() async {
    // 1) Popup для вибору акаунта
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // користувач натиснув “Cancel”

    // 2) Отримуємо токени
    final googleAuth = await googleUser.authentication;

    // 3) Формуємо credential для Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4) Авторизуємося у Firebase
    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  /// Вихід
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
