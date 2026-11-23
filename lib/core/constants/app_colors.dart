import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== Brand (shared across themes) =====
  static const Color brandPrimary = Color(0xFFC2EF00);
  static const Color brandPrimaryDark = Color(0xFF9BBF00);
  static const Color brandAccent = brandPrimary;
  static const Color brandSecondary = brandPrimaryDark;
  static const Color brandTertiary = brandPrimary;

  // ===== Light theme =====
  static const Color lightPrimaryBg = Color(0xFFFFFFFF);
  static const Color lightSecondaryBg = Color(0xFFF3F4F6);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightSurfaceBase = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF9FAFB);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceSidebar = Color(0xFFF3F4F6);
  static const Color lightSurfaceDark = Color(0xFFFFFFFF);
  static const Color lightSurfaceDarkSecondary = Color(0xFFF3F4F6);
  static const Color lightSurfaceDarkCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceDarkRaised = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);
  static const Color lightBorderDark = Color(0xFFD1D5DB);
  static const Color lightBorderGlassLight = Color(0xFFE5E7EB);
  static const Color lightBorderGlassDark = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightInkPrimary = Color(0xFF111827);
  static const Color lightInkSecondary = Color(0xFF6B7280);
  static const Color lightInkMuted = Color(0xFF9CA3AF);
  static const Color lightInkDisabled = Color(0xFFD1D5DB);
  static const Color lightInkWhite = Color(0xFFFFFFFF);
  static const Color lightGlassTintLight = Color(0xFFFFFFFF);
  static const Color lightGlassTintDark = Color(0xFFFFFFFF);

  // ===== Dark theme =====
  static const Color darkPrimaryBg = Color(0xFF000000);
  static const Color darkSecondaryBg = Color(0xFF0A0A0A);
  static const Color darkCardBg = Color(0xFF161616);
  static const Color darkSurfaceRaised = Color(0xFF1F1F1F);
  static const Color darkSurfaceBase = Color(0xFF000000);
  static const Color darkSurfaceSecondary = Color(0xFF0A0A0A);
  static const Color darkSurfaceCard = Color(0xFF161616);
  static const Color darkSurfaceSidebar = Color(0xFF0A0A0A);
  static const Color darkSurfaceDark = Color(0xFF000000);
  static const Color darkSurfaceDarkSecondary = Color(0xFF0A0A0A);
  static const Color darkSurfaceDarkCard = Color(0xFF161616);
  static const Color darkSurfaceDarkRaised = Color(0xFF1F1F1F);
  static const Color darkBorder = Color(0xFF222222);
  static const Color darkBorderSubtle = Color(0xFF222222);
  static const Color darkBorderDark = Color(0xFF222222);
  static const Color darkBorderGlassLight = Color(0xFF222222);
  static const Color darkBorderGlassDark = Color(0xFF111111);
  static const Color darkTextPrimary = Color(0xFFF4F5F0);
  static const Color darkTextSecondary = Color(0xFF888888);
  static const Color darkInkPrimary = Color(0xFFF4F5F0);
  static const Color darkInkSecondary = Color(0xFF888888);
  static const Color darkInkMuted = Color(0xFF888888);
  static const Color darkInkDisabled = Color(0xFF444444);
  static const Color darkInkWhite = Color(0xFFFFFFFF);
  static const Color darkGlassTintLight = Color(0xFF000000);
  static const Color darkGlassTintDark = Color(0xFF000000);

  // ===== Backward-compatible aliases (dark theme) =====
  static const Color primaryBg = darkPrimaryBg;
  static const Color secondaryBg = darkSecondaryBg;
  static const Color cardBg = darkCardBg;
  static const Color surfaceRaised = darkSurfaceRaised;
  static const Color surfaceBase = darkSurfaceBase;
  static const Color surfaceSecondary = darkSurfaceSecondary;
  static const Color surfaceCard = darkSurfaceCard;
  static const Color surfaceSidebar = darkSurfaceSidebar;
  static const Color surfaceDark = darkSurfaceDark;
  static const Color surfaceDarkSecondary = darkSurfaceDarkSecondary;
  static const Color surfaceDarkCard = darkSurfaceDarkCard;
  static const Color surfaceDarkRaised = darkSurfaceDarkRaised;
  static const Color border = darkBorder;
  static const Color borderSubtle = darkBorderSubtle;
  static const Color borderDark = darkBorderDark;
  static const Color borderGlassLight = Color(0xFF000000);
  static Color borderGlassDark = border.withValues(alpha: 0.1);
  static const Color inkLight = darkTextPrimary;
  static const Color inkDark = darkTextPrimary;
  static const Color inkPrimary = darkInkPrimary;
  static const Color inkSecondary = darkInkSecondary;
  static const Color inkMuted = darkInkMuted;
  static const Color inkDisabled = darkInkDisabled;
  static const Color inkWhite = darkInkWhite;
  static const Color glassTintLight = darkGlassTintLight;
  static const Color glassTintDark = darkGlassTintDark;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color surfaceLight = lightSurfaceBase;
  static const double glassOpacityLight = 0.15;
  static const double glassOpacityDark = 0.25;
  static const Color borderLight = lightBorder;

  // ===== Status / semantic colors =====
  static const Color accent = brandPrimary;
  static const Color accentDark = brandPrimaryDark;
  static const Color success = brandPrimary;
  static const Color warning = Color(0xFFF1C40F);
  static const Color danger = Color(0xFFE74C3C);
  static const Color accentSuccess = success;
  static const Color accentWarning = warning;
  static const Color accentDanger = danger;
  static const Color accentInfo = accent;
  static const Color accentPrimary = accent;

  // ===== Theme-aware helpers =====
  static Color bg(bool isDark) => isDark ? darkPrimaryBg : lightPrimaryBg;
  static Color surfaceBaseColor(bool isDark) =>
      isDark ? darkSurfaceBase : lightSurfaceBase;
  static Color surfaceRaisedColor(bool isDark) =>
      isDark ? darkSurfaceRaised : lightSurfaceRaised;
  static Color cardBgColor(bool isDark) => isDark ? darkCardBg : lightCardBg;
  static Color surfaceSidebarColor(bool isDark) =>
      isDark ? darkSurfaceSidebar : lightSurfaceSidebar;
  static Color surfaceDarkColor(bool isDark) =>
      isDark ? darkSurfaceDark : lightSurfaceDark;
  static Color surfaceDarkSecondaryColor(bool isDark) =>
      isDark ? darkSurfaceDarkSecondary : lightSurfaceDarkSecondary;
  static Color surfaceDarkCardColor(bool isDark) =>
      isDark ? darkSurfaceDarkCard : lightSurfaceDarkCard;
  static Color surfaceDarkRaisedColor(bool isDark) =>
      isDark ? darkSurfaceDarkRaised : lightSurfaceDarkRaised;
  static Color borderColor(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color borderSubtleColor(bool isDark) =>
      isDark ? darkBorderSubtle : lightBorderSubtle;
  static Color borderDarkColor(bool isDark) =>
      isDark ? darkBorderDark : lightBorderDark;
  static Color borderGlassLightColor(bool isDark) =>
      isDark ? darkBorderGlassLight : lightBorderGlassLight;
  static Color borderGlassDarkColor(bool isDark) =>
      isDark ? darkBorderGlassDark : lightBorderGlassDark;
  static Color textPrimaryColor(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondaryColor(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color inkPrimaryColor(bool isDark) =>
      isDark ? darkInkPrimary : lightInkPrimary;
  static Color inkSecondaryColor(bool isDark) =>
      isDark ? darkInkSecondary : lightInkSecondary;
  static Color inkMutedColor(bool isDark) =>
      isDark ? darkInkMuted : lightInkMuted;
  static Color inkDisabledColor(bool isDark) =>
      isDark ? darkInkDisabled : lightInkDisabled;
  static Color inkWhiteColor(bool isDark) =>
      isDark ? darkInkWhite : lightInkWhite;

  static Color getStatusColor(String status, {bool isDark = true}) {
    return _getStatusColorDark(status);
  }

  static Color _getStatusColorDark(String status) {
    switch (status) {
      case 'settled':
      case 'paid':
        return success;
      case 'ptp_scheduled':
      case 'pending':
        return warning;
      case 'written_off':
      case 'overdue':
        return danger;
      case 'active':
      default:
        return danger;
    }
  }

  static Color getBackgroundColor(BuildContext context, {bool isDark = true}) {
    return bg(isDark);
  }
}
