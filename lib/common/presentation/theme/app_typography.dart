import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale. QualiTrack Web uses Roboto, which is the Android default.
abstract final class AppTypography {
  static const String monospace = 'monospace';

  static TextTheme textTheme(TextTheme base) {
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
          bodySmall: base.bodySmall?.copyWith(color: AppColors.textMuted),
          labelSmall: base.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        )
        .apply(fontFamily: 'Roboto');
  }

  /// Large metric value used by KPI and telemetry cards.
  static const TextStyle metric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  /// Uppercase caption used above key/value pairs.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textMuted,
  );
}
