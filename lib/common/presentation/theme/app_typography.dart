import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale. QualiTrack uses Rubik (400/500/600/700); titles use the
/// brand navy and body text the slate tones.
abstract final class AppTypography {
  static const String fontFamily = 'Rubik';
  static const String monospace = 'monospace';

  static TextTheme textTheme(TextTheme base) {
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textPrimary),
          bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textPrimary),
          bodySmall: base.bodySmall?.copyWith(color: AppColors.textMuted),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          labelSmall: base.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        )
        .apply(fontFamily: fontFamily);
  }

  /// Large metric value used by KPI and telemetry cards.
  static const TextStyle metric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  /// Uppercase caption used above key/value pairs.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textMuted,
  );
}
