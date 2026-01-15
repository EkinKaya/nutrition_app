import 'package:flutter/material.dart';

/// Beslenmenin Arkadaşı - Figma'dan uyarlanan renk paleti
class AppColors {
  AppColors._();

  // Background Colors
  static const Color background = Color(0xFFFAF8F5);
  static const Color backgroundAlt = Color(0xFFF5F1ED);
  
  // Primary Colors
  static const Color primary = Color(0xFFFF6B35); // Turuncu
  static const Color primaryLight = Color(0xFFFF8A5E);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6); // Mor
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  
  // Accent Colors
  static const Color accentTurkuaz = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentYellow = Color(0xFFF59E0B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // UI Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBackground = Color(0xFFF8FAFC);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient turkuazGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Rainbow Platform (for fruit character)
  static const List<Color> rainbowColors = [
    Color(0xFFFF6B35), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Turkuaz
    Color(0xFF10B981), // Green
  ];
}