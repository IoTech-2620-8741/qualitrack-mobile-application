import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../screens/all_measurements_page.dart';
import '../widgets/measurement_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/see_more_button.dart';
import '../widgets/swipe_hint.dart';

class MeasurementsTab extends StatelessWidget {
  const MeasurementsTab({
    super.key,
    required this.data,
    required this.onReload,
    required this.onSeeLast31Days,
  });

  final ReportsData data;
  final VoidCallback onReload;
  final VoidCallback onSeeLast31Days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final grouped = data.measurementsByEnvironment;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (grouped.isEmpty)
            EmptyStateView(
              icon: Icons.analytics_outlined,
              message: l10n.noReadingsInPeriod,
              onAction: onSeeLast31Days,
              actionLabel: l10n.seeLast31Days,
            )
          else ...[
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm, left: 4),
                child: Text(
                  (data.environmentNames[entry.key] ?? '').toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final s in entry.value) MeasurementRow(summary: s, data: data),
            ],
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.totalReadings(data.totalReadings),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SeeMoreButton(
              icon: Icons.list_alt,
              label: l10n.seeAll,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AllMeasurementsPage(data: data)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SwipeHint(),
          ],
        ],
      ),
    );
  }
}