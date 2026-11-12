import 'package:flutter/material.dart';

class GlassmorphismContainer extends StatelessWidget {
  final bool isDark;
  final Border? border;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassmorphismContainer({
    super.key,
    required this.isDark,
    this.border,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: child,
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final bool obscureText;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    required this.isDark,
    this.padding,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}