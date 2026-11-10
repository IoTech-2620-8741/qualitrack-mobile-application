import 'package:flutter/material.dart';

/// QualiTrack color tokens, aligned with the QualiTrack Web palette.
/// Every color used by widgets must come from here.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D9488);

  /// Buttons, focus rings and the active navigation icon.
  static const Color primaryDark = Color(0xFF0F766E);

  /// Pressed / hovered state of primary surfaces.
  static const Color primaryHover = Color(0xFF115E59);

  /// Tonal container for active elements (selected nav item, chips).
  static const Color primaryContainer = Color(0xFFF0FDFA);
  static const Color heroStart = Color(0xFF115E59);
  static const Color heroEnd = Color(0xFF0D9488);

  /// Main titles.
  static const Color navy = Color(0xFF1A3A5C);

  // Neutrals
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic. `success`, `warning` and `critical` are the text tones (they
  // keep a 4.5:1 contrast on their container); the `*Base` tones are for
  // icons, indicators and accents only, never for body text.
  static const Color success = Color(0xFF1B5E20);
  static const Color successBase = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFF7A5A00);
  static const Color warningBase = Color(0xFFFFC107);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color critical = Color(0xFFB71C1C);
  static const Color criticalBase = Color(0xFFF44336);
  static const Color criticalContainer = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color neutralContainer = Color(0xFFF1F5F9);

  // Charts
  static const Color chartLine = Color(0xFF0D9488);
  static const Color chartCritical = Color(0xFFF44336);
  static const Color chartWarning = Color(0xFFFFC107);
  static const Color chartNormalRange = Color(0xFF4CAF50);
}
