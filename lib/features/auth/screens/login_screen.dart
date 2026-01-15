import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form_card.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthProvider _authProvider = AuthProvider();

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              LoginHeader(),
              const SizedBox(height: 40),
              LoginFormCard(authProvider: _authProvider),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}