import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_page_transition.dart';
import '../providers/auth_provider.dart';
import 'auth_input_field.dart';
import 'gradient_button.dart';
import '../screens/register_screen.dart';
import '../../home/screens/main_navigation_screen.dart';

class LoginFormCard extends StatefulWidget {
  final AuthProvider authProvider;

  const LoginFormCard({
    super.key,
    required this.authProvider,
  });

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final success = await widget.authProvider.login(context);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        AnimatedPageTransition(
          page: const MainNavigationScreen(),
          characterWalksIn: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authProvider,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 24),
              AuthInputField(
                label: 'E-posta',
                hint: 'ornek@mail.com',
                controller: widget.authProvider.emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                label: 'Şifre',
                hint: '••••••••',
                controller: widget.authProvider.passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Giriş Yap',
                onPressed: _handleLogin,
                isLoading: widget.authProvider.isLoading,
                gradient: AppColors.secondaryGradient,
              ),
              const SizedBox(height: 20),
              _buildSignupLink(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tekrar hoş geldin',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Giriş yap, kişisel planına devam et.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            AnimatedPageTransition(
              page: const RegisterScreen(),
              characterWalksIn: true,
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Hesabın yok mu? '),
              TextSpan(
                text: 'Üye Ol',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}