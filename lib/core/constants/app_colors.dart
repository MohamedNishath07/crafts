import 'package:flutter/material.dart';

/// Glassmorphism color palette - optimized for both light and dark mode
class AppColors {
  AppColors._();

  // ===== BRAND COLORS =====
  static const Color brandPrimary = Color(0xFF0F8D65);       // Teal green - primary brand
  static const Color brandAccent = Color(0xFF6DD5CF);       // Light teal - accents
  static const Color brandSecondary = Color(0xFF16A085);    // Darker teal
  static const Color brandTertiary = Color(0xFF1ABC9C);     // Bright teal

  // ===== SURFACE COLORS =====
  // Light mode surfaces
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceBase = Color(0xFFF8F9FA);
  static const Color surfaceSecondary = Color(0xFFECF0F1);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSidebar = Color(0xFFF0F4F8);
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  // Dark mode surfaces
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceDarkSecondary = Color(0xFF16213E);
  static const Color surfaceDarkCard = Color(0xFF0D1117);
  static const Color surfaceDarkRaised = Color(0xFF1D2638);

  // ===== BORDER COLORS =====
  static const Color borderLight = Color(0xFFC1C7D0);
  static const Color borderSubtle = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF4A4A60);
  static Color borderGlassLight = Color(0xFFC1C7D0).withValues(alpha: 0.3);
  static Color borderGlassDark = Color(0xFF4A4A60).withValues(alpha: 0.1);

  // ===== TEXT COLORS =====
  static const Color inkLight = Color(0xFF1C2B36);
  static const Color inkDark = Color(0xFFE0E0E0);
  static const Color inkPrimary = Color(0xFF2D3436);
  static const Color inkSecondary = Color(0xFF8D99AE);
  static const Color inkMuted = Color(0xFFB2BEB5);
  static const Color inkDisabled = Color(0xFFDEE2E6);
  static const Color inkWhite = Color(0xFFFFFFFF);

  // ===== GLASSMORPHISM SPECIFIC =====
  // Glass opacity values
  static const double glassOpacityLight = 0.15;
  static const double glassOpacityDark = 0.25;

  // Glass color tints
  static const Color glassTintLight = Color(0xFFEAF5F2);
  static const Color glassTintDark = Color(0xFF1A1A2E);

  // Accent colors - updated for soft UI
  static const Color accentSuccess = Color(0xFF2ECC71);
  static const Color accentWarning = Color(0xFFF1C40F);
  static const Color accentDanger = Color(0xFFE74C3C);
  static const Color accentInfo = Color(0xFF3498DB);
  static const Color accentPrimary = Color(0xFF0F8D65);

  // Status colors mapping
  static Color getStatusColor(String status, {bool isDark = false}) {
    if (isDark) return _getStatusColorDark(status);
    return _getStatusColorLight(status);
  }

  static Color _getStatusColorLight(String status) {
    switch (status) {
      case 'settled': return accentSuccess;
      case 'ptp_scheduled': return accentWarning;
      case 'written_off': return accentDanger;
      case 'active':
      default: return accentDanger;
    }
  }

  static Color _getStatusColorDark(String status) {
    switch (status) {
      case 'settled': return Color(0xFF27AE60);
      case 'ptp_scheduled': return Color(0xFFF39C10);
      case 'written_off': return Color(0xFFC0392B);
      case 'active':
      default: return Color(0xFFE74C3C);
    }
  }

  // ===== BACKGROUND COLORS =====
  static Color getBackgroundColor(BuildContext context, {bool isDark = false}) {
    if (isDark) return surfaceDark;
    return surfaceLight;
  }
}
