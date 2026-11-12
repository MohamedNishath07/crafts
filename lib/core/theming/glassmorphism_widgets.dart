import 'package:flutter/material.dart';
import 'package:crafts/core/constants/app_colors.dart';

/// Glassmorphism text field decorator with frosted glass effect
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final bool obscureText;
  final FormFieldValidator? validator;
  final bool? isDark;
  final EdgeInsetsGeometry? padding;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.validator,
    this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.borderGlassLight, width: 1),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: dark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 1.5),
        ),
      ),
    );
  }
}

/// Glassmorphism container with frosted glass effect
class GlassmorphismContainer extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double borderRadius;
  final Color? tintColor;
  final BoxShadow? shadow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool? isDark;
  final Border? border;

  const GlassmorphismContainer({
    super.key,
    this.child,
    this.blur = 20,
    this.borderRadius = 20,
    this.tintColor,
    this.shadow,
    this.margin,
    this.padding,
    this.isDark,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final color = dark ? AppColors.surfaceDarkCard : AppColors.surfaceCard;
    final blurValue = dark ? blur + 5 : blur;
    final shadowColor = dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tintColor ?? color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadow != null
            ? [shadow!]
            : [
          BoxShadow(
            color: shadowColor,
            blurRadius: blurValue,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}