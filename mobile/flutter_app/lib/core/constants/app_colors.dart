import 'package:flutter/material.dart';

/// نظام الألوان الأكاديمي لتطبيق Qrono
/// Academic Color System - IHM Compliant
class AppColors {
  AppColors._();

  // ── Premium Gradients (The signature Look) ──────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF0F2547), // Deep Space Navy
    Color(0xFF1B3A6B), // Royal Academic Blue
  ];

  static const List<Color> accentGradient = [
    Color(0xFFC8963C), // Gold
    Color(0xFFE8B96A), // Light Gold
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];

  // ── Core Colors ────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1B3A6B);
  static const Color accent         = Color(0xFFC8963C);
  static const Color background     = Color(0xFFF1F5F9); // Lighter, modern slate
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardColor      = Color(0xFFFFFFFF);
  
  // ── Glassmorphism Effects ──────────────────────────────────────
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassNavy(double opacity)  => const Color(0xFF0F2547).withOpacity(opacity);

  // ── Texts ──────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0F172A); // Carbon Navy
  static const Color textSecondary  = Color(0xFF475569); // Slate Grey
  static const Color textLight      = Color(0xFF94A3B8);
  static const Color textOnDark     = Color(0xFFFFFFFF);

  // ── Semantic States ───────────────────────────────────────────
  static const Color success        = Color(0xFF10B981); // Emerald
  static const Color danger         = Color(0xFFEF4444); // Rose/Red
  static const Color warning        = Color(0xFFF59E0B); // Amber
  static const Color info           = Color(0xFF3B82F6); // Blue
  
  // ── Border & Dividers ──────────────────────────────────────────
  static const Color border         = Color(0xFFE2E8F0);
  static const Color divider        = Color(0xFFF1F5F9);
  static const Color borderColor    = Color(0xFFE2E8F0); // Alias for legacy/custom screens

  // ── Additional Palette (Compatibility) ─────────────────────────
  static const Color primaryTeal    = Color(0xFF1B3A6B); // Aliasing to existing primary
  static const Color grayText       = Color(0xFF475569); // Aliasing to existing textSecondary

  // ── Premium Shadows ────────────────────────────────────────────
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> activeShadow = [
    BoxShadow(
      color: const Color(0xFF1B3A6B).withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
