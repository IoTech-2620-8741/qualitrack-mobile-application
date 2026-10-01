import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../bloc/alerts_bloc.dart';
import '../widgets/alert_widgets.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  String _filterLabel(BuildContext context, AlertFilter filter) {
    final l10n = context.l10n;
    return switch (filter) {
      AlertFilter.all => l10n.filterAll,
      AlertFilter.unresolved => l10n.alertUnresolved,
      AlertFilter.acknowledged => l10n.alertAcknowledged,
      AlertFilter.resolved => l10n.alertResolved,
      AlertFilter.critical => l10n.severityCritical,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<AlertsBloc>();
    void reload() => bloc.add(const AlertsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertsTitle),
        actions: [
          IconButton(tooltip: l10n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) => RemoteStateView<AlertsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.verified_outlined,
          emptyTitle: l10n.alertsEmptyTitle,
          emptyMessage: l10n.alertsEmptyMessage,
          builder: (context, data) {
            final summary = data.summary;
            final items = state.visible;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: l10n.alertsTitle, subtitle: l10n.alertsSubtitle),
                  const SizedBox(height: AppSpacing.md),
                  ResponsiveGrid(
                    minItemWidth: 140,
                    children: [
                      MetricTile(
                        label: l10n.totalAlerts,
                        value: '${summary.total}',
                        icon: Icons.notifications_outlined,
                        color: AppColors.navy,
                      ),
                      MetricTile(
                        label: l10n.alertUnresolved,
                        value: '${summary.unresolved}',
                        icon: Icons.report_gmailerrorred_outlined,
                        color: AppColors.critical,
                      ),
                      MetricTile(
                        label: l10n.alertAcknowledged,
                        value: '${summary.acknowledged}',
                        icon: Icons.visibility_outlined,
                        color: AppColors.info,
                      ),
                      MetricTile(
                        label: l10n.alertResolved,
                        value: '${summary.resolved}',
                        icon: Icons.task_alt,
                        color: AppColors.success,
                      ),
                      MetricTile(
                        label: l10n.criticalOpen,
                        value: '${summary.critical}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.critical,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilterChipBar<AlertFilter>(
                    options: AlertFilter.values,
                    selected: state.filter,
                    labelOf: (f) => _filterLabel(context, f),
                    onSelected: (f) => bloc.add(AlertsFilterChanged(f)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    SizedBox(height: 200, child: EmptyView(title: l10n.noResults))
                  else
                    for (final alert in items) ...[
                      AlertCard(
                        alert: alert,
                        equipmentName: data.equipmentNames[alert.equipmentId],
                        onTap: () async {
                          await context.push('/alerts/${alert.id}');
                          reload();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
