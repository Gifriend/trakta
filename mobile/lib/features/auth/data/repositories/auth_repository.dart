import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/bootstrap.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);
final authSessionProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

class AuthRepository {
  const AuthRepository(this._auth);
  final FirebaseAuth _auth;
  Stream<User?> watchUser() => _auth.userChanges();
  User? get currentUser => _auth.currentUser;
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);
  Future<void> register(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);
  }

  Future<void> resetPassword(String email, String locale) async {
    await _auth.setLanguageCode(locale);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
