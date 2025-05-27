// lib/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Ваш FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn з явним clientId для web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '645034820770-08i24pd0cragdlnht64nrlpahdujck32.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('FirebaseAuthException: $e\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unexpected error: $e\n$stack');
      rethrow;
    }
  }

  /// Вихід
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
