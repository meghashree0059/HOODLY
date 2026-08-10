import 'package:flutter/material.dart';

/// Hoodly Brand Color Palette
abstract final class AppColors {
  // ── Primary ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C3EF4);
  static const Color primaryDark = Color(0xFF4F2ED9);
  static const Color primaryLight = Color(0xFF8B65F7);

  // ── Secondary ────────────────────────────────────────────────
  static const Color secondary = Color(0xFFFFB800);
  static const Color secondaryLight = Color(0xFFFFD04D);

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color background = Color(0xFFF8F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F0FA);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFADADAD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Border ───────────────────────────────────────────────────
  static const Color border = Color(0xFFECECEC);
  static const Color borderFocused = Color(0xFF6C3EF4);

  // ── Utility ──────────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB800);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color shimmer = Color(0xFFE8E8EE);

  // ── Gradient ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F4FF), Color(0xFFEDE8FD)],
  );

  // ── Shadow ───────────────────────────────────────────────────
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
