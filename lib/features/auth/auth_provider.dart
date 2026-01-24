import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication business logic
class AuthProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

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