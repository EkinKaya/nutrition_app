import 'package:flutter/material.dart';

/// Beslenmenin Arkadaşı - Modern minimal design color palette
class AppColors {
  AppColors._();

  // Background Colors
  static const Color background = Color(0xFFF5F5F8); // Açık gri
  static const Color backgroundAlt = Color(0xFFFFFFFF); // Beyaz

  // Primary Colors - Lime Green
  static const Color primary = Color(0xFFD7FE03); // Parlak lime green
  static const Color primaryDark = Color(0xFF83AF3B); // Koyu yeşil
  static const Color primaryForeground = Color(0xFF000000); // Siyah

  // Dark Colors
  static const Color dark = Color(0xFF000000); // Siyah
  static const Color darkSoft = Color(0xFF1A1A1A); // Yumuşak siyah

  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Siyah
  static const Color textSecondary = Color(0xFF666666); // Koyu gri
  static const Color textLight = Color(0xFF999999); // Açık gri

  // UI Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E5);
  static const Color inputBackground = Color(0xFFF5F5F8);

  // Status Colors
  static const Color success = Color(0xFF83AF3B);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD7FE03), Color(0xFF83AF3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}