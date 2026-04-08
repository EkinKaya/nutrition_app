import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication business logic
class AuthProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  // Login
  Future<bool> login(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showError(context, 'Lütfen tüm alanları doldurun');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Giriş başarısız';
      if (e.code == 'user-not-found') {
        message = 'Kullanıcı bulunamadı';
      } else if (e.code == 'wrong-password') {
        message = 'Yanlış şifre';
      }
      _showError(context, message);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showError(context, 'Lütfen e-posta ve şifre girin');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showError(context, 'Şifre en az 6 karakter olmalı');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt başarısız';
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kullanımda';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi';
      }
      _showError(context, message);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google ile giriş / kayıt
  Future<SocialAuthResult> signInWithGoogle(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Kullanıcı iptal etti
        return SocialAuthResult.cancelled;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      return isNew ? SocialAuthResult.newUser : SocialAuthResult.existingUser;
    } on FirebaseAuthException catch (e) {
      _showError(context, e.message ?? 'Google girişi başarısız');
      return SocialAuthResult.error;
    } catch (_) {
      _showError(context, 'Google girişi başarısız');
      return SocialAuthResult.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

enum SocialAuthResult { newUser, existingUser, cancelled, error }