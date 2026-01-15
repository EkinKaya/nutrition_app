import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/fruit_character.dart';

class LoginHeader extends StatefulWidget {
  const LoginHeader({super.key});

  @override
  State<LoginHeader> createState() => _LoginHeaderState();
}

class _LoginHeaderState extends State<LoginHeader> {
  final List<String> _motivations = [
    'Sağlıklı beslenmenin en kolay yolu',
    'Her öğün bir macera',
    'Besinlerinizle arkadaş olun',
    'Lezzetli ve sağlıklı bir araya gelir',
  ];
  
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _motivations.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 16),
        _buildAppName(),
        const SizedBox(height: 12),
        _buildAnimatedMotivation(),
      ],
    );
  }

  Widget _buildLogo() {
    return FruitCharacter(
      size: FruitSize.small,
      action: FruitAction.celebrating,
      showPlatform: false,
    );
  }

  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFFF6B35),
          Color(0xFF8B5CF6),
          Color(0xFF10B981),
        ],
      ).createShader(bounds),
      child: Text(
        'Beslenmenin Arkadaşı',
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1.0,
          height: 1.1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnimatedMotivation() {
    return SizedBox(
      height: 50,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: ShaderMask(
          key: ValueKey(_currentIndex),
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF10B981),
            ],
          ).createShader(bounds),
          child: Text(
            _motivations[_currentIndex],
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}