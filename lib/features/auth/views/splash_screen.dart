import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Timer _textTimer;
  int _currentMotivationIndex = 0;

  final List<String> _motivations = [
    'Sağlıklı beslenmenin en kolay yolu',
    'Her öğün bir macera',
    'Besinlerinizle arkadaş olun',
    'Lezzetli ve sağlıklı bir araya gelir',
    'Kişiye özel beslenme planları',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Her 600ms'de bir motivasyon cümlesi değiştir
    _textTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _currentMotivationIndex = (_currentMotivationIndex + 1) % _motivations.length;
        });
      }
    });

    // 2.5 saniye sonra otomatik geçiş
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _textTimer.cancel();
        _controller.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Lime green background
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // App İsmi - Siyah, Bold
                  Text(
                    'Beslenmenin\nArkadaşı',
                    style: GoogleFonts.urbanist(
                      fontSize: 46,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      height: 1.2,
                      letterSpacing: -1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Alt yazı - Değişen motivasyonlar
                  SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _motivations[_currentMotivationIndex],
                        key: ValueKey(_currentMotivationIndex),
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
