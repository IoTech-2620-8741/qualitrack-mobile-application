/// This file contains the Measurements Tab.
///
/// It displays the measurement summaries grouped by environment,
/// shows the total reading count, and provides a button to view the
/// complete list of measurements.
///
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

/// Tab that displays the measurement summaries.
class MeasurementsTab extends StatelessWidget {
  const MeasurementsTab({
    super.key,
    required this.data,
    required this.onReload,
    required this.onSeeLast31Days,
  });

  /// The consolidated data from the Facade.
  final ReportsData data;

  /// Callback to trigger a manual refresh.
  final VoidCallback onReload;

  /// Callback to change the period to 31 days when the list is empty.
  final VoidCallback onSeeLast31Days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // Get the measurements grouped by environment ID
    final grouped = data.measurementsByEnvironment;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (grouped.isEmpty)
          // 1. Empty state with an action to expand the time period
            EmptyStateView(
              icon: Icons.analytics_outlined,
              message: l10n.noReadingsInPeriod,
              onAction: onSeeLast31Days,
              actionLabel: l10n.seeLast31Days,
            )
          else ...[
            // 2. Iterate over the grouped measurements
            for (final entry in grouped.entries) ...[
              // Environment header (uppercase, primary color)
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

              // Display each measurement summary in that environment
              for (final s in entry.value)
                MeasurementRow(summary: s, data: data),
            ],

            const SizedBox(height: AppSpacing.md),

            // 3. Total readings count (sum of all measurements)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.totalReadings(data.totalReadings),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 4. Button to view all measurements
            SeeMoreButton(
              icon: Icons.list_alt,
              label: l10n.seeAll,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AllMeasurementsPage(data: data)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Swipe hint for the user
            const SwipeHint(),
          ],
        ],
      ),
    );
  }
}