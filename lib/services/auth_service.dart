import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign up with email & password and set display name
  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
      await cred.user?.reload();
    }

    // Send email verification
    await cred.user?.sendEmailVerification();

    return _auth.currentUser;
  }

  // Sign in with email & password
  Future<User?> signIn({
    required String email,
    required String password,
    bool requireEmailVerified = false,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (requireEmailVerified && user != null && !user.emailVerified) {
      // Optionally sign out and throw to notify caller
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email များကို စစ်ဆေးပြီးမှ ဝင်ရောက်နိုင်ပါသည်။ သင်၏ email ကို verify လုပ်ပါ။',
      );
    }

    return user;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Force send verification email for current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
