import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/trend_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/see_more_button.dart';
import '../widgets/swipe_hint.dart';
import '../screens/all_deviations_page.dart';

class DeviationsTab extends StatelessWidget {
  const DeviationsTab({
    super.key,
    required this.data,
    required this.onReload,
    required this.onSeeLast31Days,
  });

  final ReportsData data;
  final VoidCallback onReload;
  final VoidCallback onSeeLast31Days;

  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trends = data.sortedTrends;

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (trends.isEmpty)
            EmptyStateView(
              icon: Icons.insights_outlined,
              message: l10n.noReadingsInPeriod,
              onAction: onSeeLast31Days,
              actionLabel: l10n.seeLast31Days,
            )
          else ...[
            for (final t in trends.take(_maxVisible)) TrendRow(trend: t, data: data),
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
            const SwipeHint(),
          ],
        ],
      ),
    );
  }
}