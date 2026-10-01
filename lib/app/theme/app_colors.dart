import 'package:flutter/material.dart';

/// QualiTrack color tokens extracted from the Angular web app and the mobile
/// mockups. Every color used by widgets must come from here.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0E8066);
  static const Color primaryDark = Color(0xFF107562);
  static const Color primaryContainer = Color(0xFFE3F4EF);
  static const Color heroStart = Color(0xFF0B4744);
  static const Color heroEnd = Color(0xFF0E8066);
  static const Color navy = Color(0xFF1A3A5C);

  // Neutrals
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1A3353);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic
  static const Color success = Color(0xFF1E7E34);
  static const Color successContainer = Color(0xFFE6F4EA);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color critical = Color(0xFFB91C1C);
  static const Color criticalContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color neutralContainer = Color(0xFFF1F5F9);

  // Charts
  static const Color chartLine = Color(0xFF0D9488);
  static const Color chartAnomaly = Color(0xFFEF4444);
  static const Color chartLimit = Color(0xFFF59E0B);
}
