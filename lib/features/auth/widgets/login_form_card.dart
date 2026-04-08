import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../shared/widgets/animated_page_transition.dart';
import '../auth_provider.dart';
import 'auth_input_field.dart';
import '../views/register_screen.dart';
import '../../navigation/views/main_navigation_screen.dart';

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

  Future<void> _handleGoogleSignIn() async {
    final result = await widget.authProvider.signInWithGoogle(context);
    if (!mounted) return;
    if (result == SocialAuthResult.newUser) {
      // Yeni kullanıcı — Firestore profili oluştur
      final email = widget.authProvider.emailController.text.isNotEmpty
          ? widget.authProvider.emailController.text
          : (await _getFirebaseEmail());
      await UserService.createUserProfile(email: email);
    }
    if ((result == SocialAuthResult.newUser ||
            result == SocialAuthResult.existingUser) &&
        mounted) {
      Navigator.of(context).pushReplacement(
        AnimatedPageTransition(
          page: const MainNavigationScreen(),
          characterWalksIn: true,
        ),
      );
    }
  }

Future<String> _getFirebaseEmail() async {
    // Firebase Auth'tan mevcut kullanıcının emailini al
    return widget.authProvider.currentUserEmail ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authProvider,
      builder: (context, child) {
        return Column(
          children: [
            // Email input
            AuthInputField(
              label: 'Email',
              hint: 'Email adresini gir',
              controller: widget.authProvider.emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDarkTheme: true,
            ),

            const SizedBox(height: 16),

            // Password input
            AuthInputField(
              label: 'Şifre',
              hint: 'Şifreni gir',
              controller: widget.authProvider.passwordController,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              isDarkTheme: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Şifremi unuttum',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Login button - Lime green
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.authProvider.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.dark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: widget.authProvider.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.dark),
                        ),
                      )
                    : Text(
                        'Giriş Yap',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Or divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'veya',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Google butonu
            SizedBox(
              width: double.infinity,
              child: _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google ile Giriş Yap',
                onPressed: widget.authProvider.isLoading
                    ? null
                    : _handleGoogleSignIn,
              ),
            ),

            const SizedBox(height: 32),

            // Sign up link
            _buildSignupLink(),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed != null ? () => onPressed() : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            AnimatedPageTransition(
              page: const RegisterScreen(),
              characterWalksIn: false,
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            children: [
              const TextSpan(text: 'Hesabın yok mu? '),
              TextSpan(
                text: 'Kayıt ol',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
