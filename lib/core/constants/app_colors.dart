import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette
  static const Color primaryDark = Color(0xFF0D1322);
  static const Color primaryNavy = Color(0xFF101828);
  static const Color cardNavy = Color(0xFF1A2234);
  static const Color surfaceNavy = Color(0xFF151D2C);
  static const Color secondaryWhite = Color(0xFFFFFFFF);
  
  // Modern Accents
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Backgrounds
  static const Color bgDark = Color(0xFF090D16);
  static const Color bgLight = Color(0xFFF7F8FC);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFF0F172A);
  static const Color textSecondaryDark = Color(0xFF475569);
  
  // Gradients
  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlowGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
