import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_page_transition.dart';
import '../providers/auth_provider.dart';
import 'auth_input_field.dart';
import 'gradient_button.dart';
import '../../home/screens/main_navigation_screen.dart';

class RegisterFormCard extends StatefulWidget {
  final AuthProvider authProvider;

  const RegisterFormCard({
    super.key,
    required this.authProvider,
  });

  @override
  State<RegisterFormCard> createState() => _RegisterFormCardState();
}

class _RegisterFormCardState extends State<RegisterFormCard> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleRegister() async {
    final success = await widget.authProvider.register(context);
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
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
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
              
              // Ad Soyad
              AuthInputField(
                label: 'Ad Soyad',
                hint: 'Adınız ve soyadınız',
                controller: widget.authProvider.nameController,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),
              
              const SizedBox(height: 16),
              
              // Email
              AuthInputField(
                label: 'E-posta',
                hint: 'ornek@mail.com',
                controller: widget.authProvider.emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              
              // Şifre
              AuthInputField(
                label: 'Şifre',
                hint: 'En az 6 karakter',
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
              
              const SizedBox(height: 16),
              
              // Şifre Tekrar
              AuthInputField(
                label: 'Şifre (tekrar)',
                hint: 'Şifrenizi tekrar girin',
                controller: widget.authProvider.confirmPasswordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Kayıt Ol Button
              GradientButton(
                text: 'Hesap Oluştur',
                onPressed: _handleRegister,
                isLoading: widget.authProvider.isLoading,
                gradient: AppColors.primaryGradient,
                icon: Icons.person_add,
              ),
              
              const SizedBox(height: 20),
              
              // Giriş yap linki
              _buildLoginLink(),
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
          'Hadi başlayalım!',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dakikalar içinde kişisel planını oluşturalım.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'Zaten hesabın var mı? '),
              TextSpan(
                text: 'Giriş Yap',
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