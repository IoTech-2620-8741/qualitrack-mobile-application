import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../bloc/alerts_bloc.dart';
import '../bloc/unread_notifications_controller.dart';
import '../widgets/notification_bell.dart';
import '../widgets/alert_widgets.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.notifications});

  final UnreadNotificationsController notifications;

  String _filterLabel(BuildContext context, AlertFilter filter) {
    final i18n = context.i18n;
    return switch (filter) {
      AlertFilter.open => i18n.alertsOpen,
      AlertFilter.all => i18n.filterAll,
      AlertFilter.unresolved => i18n.alertUnresolved,
      AlertFilter.acknowledged => i18n.alertAcknowledged,
      AlertFilter.resolved => i18n.alertResolved,
      AlertFilter.critical => i18n.severityCritical,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<AlertsBloc>();
    void reload() => bloc.add(const AlertsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.alertsTitle),
        actions: [
          NotificationBell(controller: notifications),
          IconButton(tooltip: i18n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) => RemoteStateView<AlertsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.verified_outlined,
          emptyTitle: i18n.alertsEmptyTitle,
          emptyMessage: i18n.alertsEmptyMessage,
          builder: (context, data) {
            final summary = data.summary;
            final items = state.visible;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: i18n.alertsTitle, subtitle: i18n.alertsSubtitle),
                  const SizedBox(height: AppSpacing.md),
                  ResponsiveGrid(
                    minItemWidth: 140,
                    children: [
                      MetricTile(
                        label: i18n.totalAlerts,
                        value: '${summary.total}',
                        icon: Icons.notifications_outlined,
                        color: AppColors.navy,
                      ),
                      MetricTile(
                        label: i18n.alertUnresolved,
                        value: '${summary.unresolved}',
                        icon: Icons.report_gmailerrorred_outlined,
                        color: AppColors.critical,
                      ),
                      MetricTile(
                        label: i18n.alertAcknowledged,
                        value: '${summary.acknowledged}',
                        icon: Icons.visibility_outlined,
                        color: AppColors.info,
                      ),
                      MetricTile(
                        label: i18n.alertResolved,
                        value: '${summary.resolved}',
                        icon: Icons.task_alt,
                        color: AppColors.success,
                      ),
                      MetricTile(
                        label: i18n.criticalOpen,
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
                    SizedBox(height: 200, child: EmptyView(title: i18n.noResults))
                  else
                    for (final alert in items) ...[
                      AlertCard(
                        alert: alert,
                        deviceName: data.deviceNames[alert.equipmentId],
                        environmentName: data.environmentNames[alert.environmentId],
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
