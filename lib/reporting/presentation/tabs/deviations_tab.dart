/// This file contains the Deviations Tab.
///
/// It displays the top deviation trends (limited to 5), provides an empty
/// state with an action to expand the period, and a button to view all deviations.
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/trend_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/see_more_button.dart';
import '../widgets/swipe_hint.dart';
import '../screens/all_deviations_page.dart';

/// Tab that displays the deviation trends.
class DeviationsTab extends StatelessWidget {
  const DeviationsTab({
    super.key,
    required this.data,
    required this.onReload,
    required this.onSeeLast31Days,
  });

  /// The consolidated data from the Facade.
  final ReportsData data;

  /// Callback to trigger a manual refresh (pull-to-refresh).
  final VoidCallback onReload;

  /// Callback to change the period to 31 days when the list is empty.
  final VoidCallback onSeeLast31Days;

  /// Maximum number of trends visible before showing the "See more" button.
  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Get the trends sorted by severity (Critical > Warning > On Track > No Data)
    final trends = data.sortedTrends;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (trends.isEmpty)
          // 1. If there are no trends, show the empty state with a button
          // to try the "Last 31 days" period.
            EmptyStateView(
              icon: Icons.insights_outlined,
              message: l10n.noReadingsInPeriod,
              onAction: onSeeLast31Days,
              actionLabel: l10n.seeLast31Days,
            )
          else ...[
            // 2. Display the first 5 trends
            for (final t in trends.take(_maxVisible))
              TrendRow(trend: t, data: data),

            // 3. If there are more than 5 trends, show the "See more" button
            if (trends.length > _maxVisible)
              SeeMoreButton(
                alignment: Alignment.centerLeft,
                icon: Icons.expand_more,
                label: l10n.seeMoreCount(trends.length - _maxVisible),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AllDeviationsPage(data: data)),
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // 4. Swipe hint for the user (to indicate they can change tabs)
            const SwipeHint(),
          ],
        ],
      ),
    );
  }
}