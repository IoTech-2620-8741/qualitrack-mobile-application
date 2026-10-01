import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

enum BadgeTone { success, warning, critical, info, neutral, brand }

extension BadgeToneColors on BadgeTone {
  Color get foreground => switch (this) {
    BadgeTone.success => AppColors.success,
    BadgeTone.warning => AppColors.warning,
    BadgeTone.critical => AppColors.critical,
    BadgeTone.info => AppColors.info,
    BadgeTone.neutral => AppColors.textSecondary,
    BadgeTone.brand => AppColors.primary,
  };

  Color get background => switch (this) {
    BadgeTone.success => AppColors.successContainer,
    BadgeTone.warning => AppColors.warningContainer,
    BadgeTone.critical => AppColors.criticalContainer,
    BadgeTone.info => AppColors.infoContainer,
    BadgeTone.neutral => AppColors.neutralContainer,
    BadgeTone.brand => AppColors.primaryContainer,
  };

  /// Every tone has its own icon so state is never conveyed by color alone.
  IconData get icon => switch (this) {
    BadgeTone.success => Icons.check_circle_outline,
    BadgeTone.warning => Icons.warning_amber_rounded,
    BadgeTone.critical => Icons.error_outline,
    BadgeTone.info => Icons.info_outline,
    BadgeTone.neutral => Icons.radio_button_unchecked,
    BadgeTone.brand => Icons.verified_outlined,
  };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
        decoration: BoxDecoration(color: tone.background, borderRadius: AppRadius.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? tone.icon, size: 14, color: tone.foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tone.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
