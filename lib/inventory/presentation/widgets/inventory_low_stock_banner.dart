
import 'package:flutter/material.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';

/// Displays a warning when raw materials have low stock.
///
/// This widget is responsible only for presentation.
/// The low-stock count is calculated by InventoryBloc.
class InventoryLowStockBanner extends StatelessWidget {
  /// Creates a low-stock warning banner.
  const InventoryLowStockBanner({
    super.key,
    required this.count,
  });

  /// Number of materials below their minimum stock.
  final int count;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                i18n.lowStockAlert(count),
                style: const TextStyle(
                  color: AppColors.warning,
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
