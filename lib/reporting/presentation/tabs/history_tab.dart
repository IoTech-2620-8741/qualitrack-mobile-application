import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/history_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/see_more_button.dart';
import '../widgets/swipe_hint.dart';
import '../widgets/info_banner.dart';
import '../screens/all_reports_page.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.data, required this.onReload});
  final ReportsData data;
  final VoidCallback onReload;

  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reports = data.reports.items;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InfoBanner(text: l10n.reportHistoryBanner),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.historyIndependentOfPeriod,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSpacing.md),
          if (reports.isEmpty)
            EmptyStateView(icon: Icons.history, message: l10n.reportHistoryEmpty)
          else ...[
            for (final r in reports.take(_maxVisible)) HistoryRow(report: r),
            if (reports.length > _maxVisible)
              SeeMoreButton(
                icon: Icons.history,
                label: l10n.seeAll,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AllReportsPage(reports: data.reports.items)),
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