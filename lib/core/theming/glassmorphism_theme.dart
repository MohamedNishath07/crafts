import 'package:flutter/material.dart';
import 'package:crafts/core/constants/app_colors.dart';

/// Custom ThemeData with glassmorphism and dark/light mode support
class GlassmorphismTheme {
  GlassmorphismTheme._();

  /// Light mode theme with glassmorphism effects
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surfaceBase,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
      primary: AppColors.brandPrimary,
      surface: AppColors.surfaceRaised,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceSidebar,
      foregroundColor: AppColors.inkPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderGlassLight, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
    ),
  );

  /// Dark mode theme with glassmorphism effects
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
      primary: AppColors.brandPrimary,
      surface: AppColors.surfaceDarkRaised,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDarkSecondary,
      foregroundColor: AppColors.inkPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDarkCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderGlassDark, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
    ),
  );

  /// Theme extension for glassmorphism support
  static ThemeExtension<GlassmorphismExtension> get extension => GlassmorphismExtension();
}

/// Glassmorphism theme extension for custom properties
class GlassmorphismExtension extends ThemeExtension<GlassmorphismExtension> {
  final Color surfaceLight;
  final Color surfaceDark;
  final Color glassTintLight;
  final Color glassTintDark;
  final double glassOpacityLight;
  final double glassOpacityDark;
  final Color borderLight;
  final Color borderDark;

  const GlassmorphismExtension({
    this.surfaceLight = AppColors.surfaceLight,
    this.surfaceDark = AppColors.surfaceDark,
    this.glassTintLight = AppColors.glassTintLight,
    this.glassTintDark = AppColors.glassTintDark,
    this.glassOpacityLight = AppColors.glassOpacityLight,
    this.glassOpacityDark = AppColors.glassOpacityDark,
    this.borderLight = AppColors.borderLight,
    this.borderDark = AppColors.borderDark,
  });

  @override
  ThemeExtension<GlassmorphismExtension> copyWith({
    Color? surfaceLight,
    Color? surfaceDark,
    Color? glassTintLight,
    Color? glassTintDark,
    double? glassOpacityLight,
    double? glassOpacityDark,
    Color? borderLight,
    Color? borderDark,
  }) => GlassmorphismExtension(
    surfaceLight: surfaceLight ?? this.surfaceLight,
    surfaceDark: surfaceDark ?? this.surfaceDark,
    glassTintLight: glassTintLight ?? this.glassTintLight,
    glassTintDark: glassTintDark ?? this.glassTintDark,
    glassOpacityLight: glassOpacityLight ?? this.glassOpacityLight,
    glassOpacityDark: glassOpacityDark ?? this.glassOpacityDark,
    borderLight: borderLight ?? this.borderLight,
    borderDark: borderDark ?? this.borderDark,
  );

  @override
  ThemeExtension<GlassmorphismExtension> lerp(
    covariant ThemeExtension<GlassmorphismExtension>? other,
    double t,
  ) {
    if (other is! GlassmorphismExtension) return this;
    return GlassmorphismExtension(
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      glassTintLight: Color.lerp(glassTintLight, other.glassTintLight, t)!,
      glassTintDark: Color.lerp(glassTintDark, other.glassTintDark, t)!,
      glassOpacityLight: glassOpacityLight + (other.glassOpacityLight - glassOpacityLight) * t,
      glassOpacityDark: glassOpacityDark + (other.glassOpacityDark - glassOpacityDark) * t,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDark: Color.lerp(borderDark, other.borderDark, t)!,
    );
  }
}