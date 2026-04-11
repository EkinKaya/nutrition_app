import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../auth_provider.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/scrollable_age_picker.dart';
import '../widgets/ruler_weight_picker.dart';
import '../widgets/ruler_height_picker.dart';
import 'congratulation_screen.dart';
import '../../../shared/widgets/animated_page_transition.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthProvider _authProvider = AuthProvider();
  final PageController _pageController = PageController();
  bool _obscurePassword = true;
  int _currentPage = 0;

  // Optional fields - sadece kullanici secim yaparsa deger atanir
  int? _selectedAge;
  int? _selectedWeight;
  int? _selectedHeight;
  String? _selectedGender;
  String? _selectedDiet;

  // Kullanici gercekten secim yapti mi?
  bool _hasSelectedAge = false;
  bool _hasSelectedWeight = false;
  bool _hasSelectedHeight = false;

  @override
  void dispose() {
    _authProvider.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipPage() {
    // Secimi sifirla ve sonraki sayfaya gec
    setState(() {
      switch (_currentPage) {
        case 0:
          _selectedAge = null;
          _hasSelectedAge = false;
          break;
        case 1:
          _selectedWeight = null;
          _hasSelectedWeight = false;
          break;
        case 2:
          _selectedHeight = null;
          _hasSelectedHeight = false;
          break;
        case 3:
          _selectedGender = null;
          break;
        case 4:
          _selectedDiet = null;
          break;
      }
    });
    _nextPage();
  }

  Future<void> _handleRegister() async {
    final success = await _authProvider.register(context);
    if (success && mounted) {
      // Kullanıcı verilerini Firestore'a kaydet
      // Sadece kullanici secim yaptiysa degeri gonder, yoksa null
      await UserService.createUserProfile(
        email: _authProvider.emailController.text,
        age: _hasSelectedAge ? _selectedAge : null,
        weight: _hasSelectedWeight ? _selectedWeight : null,
        height: _hasSelectedHeight ? _selectedHeight : null,
        gender: _selectedGender,
        dietType: _selectedDiet,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          AnimatedPageTransition(
            page: const CongratulationScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentPage == 0
                        ? () => Navigator.of(context).pop()
                        : _previousPage,
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hesap Oluştur',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(7, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildAgePage(),
                  _buildWeightPage(),
                  _buildHeightPage(),
                  _buildGenderPage(),
                  _buildDietPage(),
                  _buildEmailPage(),
                  _buildPasswordPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optional sayfalar icin buton satiri (Gec + Devam Et)
  Widget _buildOptionalButtons({bool hasSelection = false}) {
    return Row(
      children: [
        // Gec butonu
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _skipPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Geç',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Devam Et butonu
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Devam Et',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kaç yaşındasın?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi isteğe bağlıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ScrollableAgePicker(
              initialAge: _selectedAge ?? 25,
              onAgeChanged: (age) {
                setState(() {
                  _selectedAge = age;
                  _hasSelectedAge = true;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildOptionalButtons(hasSelection: _hasSelectedAge),
        ],
      ),
    );
  }

  Widget _buildWeightPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kilon kaç?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi isteğe bağlıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: RulerWeightPicker(
              initialWeight: _selectedWeight ?? 70,
              onWeightChanged: (weight) {
                setState(() {
                  _selectedWeight = weight;
                  _hasSelectedWeight = true;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildOptionalButtons(hasSelection: _hasSelectedWeight),
        ],
      ),
    );
  }

  Widget _buildHeightPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Boyun kaç?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi isteğe bağlıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RulerHeightPicker(
                  initialHeight: _selectedHeight ?? 170,
                  onHeightChanged: (height) {
                    setState(() {
                      _selectedHeight = height;
                      _hasSelectedHeight = true;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionalButtons(hasSelection: _hasSelectedHeight),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cinsiyetin nedir?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi isteğe bağlıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          _buildGenderOption('Erkek', Icons.male),
          const SizedBox(height: 16),
          _buildGenderOption('Kadın', Icons.female),
          const SizedBox(height: 16),
          _buildGenderOption('Belirtmek istemiyorum', Icons.person_outline),
          const Spacer(),
          _buildOptionalButtons(hasSelection: _selectedGender != null),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = gender);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.dark : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              gender,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.dark : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beslenme tercihin nedir?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi isteğe bağlıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          _buildDietOption('Her şey', 'Tüm besinler'),
          const SizedBox(height: 16),
          _buildDietOption('Vejetaryen', 'Et içermeyen'),
          const SizedBox(height: 16),
          _buildDietOption('Vegan', 'Hayvansal ürün içermeyen'),
          const SizedBox(height: 16),
          _buildDietOption('Pesketaryen', 'Sadece balık ve deniz ürünleri'),
          const Spacer(),
          _buildOptionalButtons(hasSelection: _selectedDiet != null),
        ],
      ),
    );
  }

  Widget _buildDietOption(String diet, String description) {
    final isSelected = _selectedDiet == diet;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDiet = diet);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diet,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.dark : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.dark.withOpacity(0.7)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.dark,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email adresin nedir?',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilgi zorunludur',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          AuthInputField(
            label: 'Email',
            hint: 'ornek@mail.com',
            controller: _authProvider.emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDarkTheme: true,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_authProvider.emailController.text.isNotEmpty) {
                  _nextPage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lütfen email adresinizi girin',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Devam Et',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Şifreni belirle',
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En az 6 karakter olmalıdır',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          AuthInputField(
            label: 'Şifre',
            hint: 'En az 6 karakter',
            controller: _authProvider.passwordController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            isDarkTheme: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _authProvider,
            builder: (context, child) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _authProvider.isLoading
                      ? null
                      : () {
                          if (_authProvider.passwordController.text.length >= 6) {
                            _handleRegister();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Şifre en az 6 karakter olmalıdır',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.dark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.dark,
                            ),
                          ),
                        )
                      : Text(
                          'Hesap Oluştur',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
