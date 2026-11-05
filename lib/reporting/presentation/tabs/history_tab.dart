/// This file contains the History Tab.
///
/// It displays a banner explaining how reports are generated, a note indicating
/// that history is independent of the selected period, and the list of the
/// most recent reports with a button to view all of them.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/history_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/see_more_button.dart';
import '../widgets/swipe_hint.dart';
import '../widgets/info_banner.dart';
import '../screens/all_reports_page.dart';

/// Tab that displays the history of generated reports.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.data, required this.onReload});

  /// The consolidated data from the Facade.
  final ReportsData data;

  /// Callback to trigger a manual refresh (pull-to-refresh).
  final VoidCallback onReload;

  /// Maximum number of reports visible before showing the "See all" button.
  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);

    // Get the list of reports from the data object
    final reports = data.reports.items;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Information banner explaining that reports are generated on the Web
          InfoBanner(text: i18n.reportHistoryBanner),
          const SizedBox(height: AppSpacing.md),

          // 2. Note indicating that the history is independent of the selected period
          Text(
            i18n.historyIndependentOfPeriod,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. List of reports (or empty state)
          if (reports.isEmpty)
            EmptyStateView(icon: Icons.history, message: i18n.reportHistoryEmpty)
          else ...[
            // Display the first 5 reports
            for (final r in reports.take(_maxVisible))
              HistoryRow(report: r),

            // If there are more than 5 reports, show the "See all" button
            if (reports.length > _maxVisible)
              SeeMoreButton(
                icon: Icons.history,
                label: i18n.seeAll,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AllReportsPage(reports: data.reports.items)),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // 4. Swipe hint for the user
            const SwipeHint(),
          ],
        ],
      ),
    );
  }
}