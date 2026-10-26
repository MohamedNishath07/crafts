import 'package:flutter/material.dart';

/// AppColors defines the visual tokens specified in DESIGN.md.
/// Theme: Trustworthy Fintech (Slate/Navy with semantic accents).
class AppColors {
  AppColors._();

  // Surface Canvas
  static const Color surfaceBase = Color(0xFFF8FAFC);      // Slate 50
  static const Color surfaceRaised = Color(0xFFFFFFFF);    // Pure White
  static const Color surfaceSidebar = Color(0xFF0F172A);   // Deep Navy / Slate 900
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Brand Primaries
  static const Color brandPrimary = Color(0xFF0F172A);     // Slate 900
  static const Color brandAccent = Color(0xFF1E293B);      // Slate 800
  static const Color brandPrimaryLight = Color(0xFF334155);// Slate 700

  // Ink / Text
  static const Color inkPrimary = Color(0xFF0F172A);       // Dark Text
  static const Color inkSecondary = Color(0xFF475569);     // Subtitle / Label
  static const Color inkMuted = Color(0xFF94A3B8);         // Placeholder / Inactive
  static const Color inkWhite = Color(0xFFFFFFFF);

  // Semantic Status Tints
  static const Color accentSuccess = Color(0xFF10B981);    // Emerald 500 (Paid / Recovered)
  static const Color accentWarning = Color(0xFFF59E0B);    // Amber 500 (PTP Due / Approaching)
  static const Color accentDanger = Color(0xFFEF4444);     // Rose 500 (Overdue / Broken PTP)
  static const Color accentUrgent = Color(0xFF991B1B);     // Deep Red (90+ DPD)
  static const Color accentInfo = Color(0xFF0284C7);       // Sky 600

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0);     // Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1);     // Slate 300
}
