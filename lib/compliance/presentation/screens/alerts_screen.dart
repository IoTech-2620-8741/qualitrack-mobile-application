import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/fab_menu.dart';
import '../../../common/presentation/widgets/filter_summary_card.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/alert_summary.dart';
import '../../domain/entities/deviation_alert.dart';
import '../bloc/alerts_bloc.dart';
import '../widgets/alert_widgets.dart';

/// Deviation alerts of the laboratory.
///
/// A compact summary card for the filter in use, a search bar and the
/// matching alerts. The filter is chosen from a FAB menu at the bottom-right
/// corner, where each option shows how many alerts it has.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<AlertsBloc>();
    void reload() => bloc.add(const AlertsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(title: i18n.alertsTitle, subtitle: i18n.alertsSubtitle)),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) => RemoteStateView<AlertsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.verified_outlined,
          emptyTitle: i18n.alertsEmptyTitle,
          emptyMessage: i18n.alertsEmptyMessage,
          builder: (context, data) {
            final summary = data.summary;
            final items = state.visible.where((a) => _matches(a, state.query, data, i18n)).toList();
            final style = _FilterStyle.of(state.filter);
            return FabMenuHost<AlertFilter>(
              icon: Icons.filter_list,
              tooltip: i18n.filterAlerts,
              selected: state.filter,
              onSelected: (f) => bloc.add(AlertsFilterChanged(f)),
              items: [
                for (final f in AlertFilter.values)
                  FabMenuItem(
                    value: f,
                    label: _FilterStyle.of(f).label(i18n),
                    icon: _FilterStyle.of(f).icon,
                    count: _count(f, summary),
                  ),
              ],
              child: RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    FabMenuHost.bottomClearance,
                  ),
                  children: [
                    FilterSummaryCard(
                      filterLabel: style.label(i18n),
                      icon: style.icon,
                      tone: style.tone,
                      count: items.length,
                      total: summary.total,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SearchField(hint: i18n.searchAlerts, onChanged: (q) => bloc.add(AlertsQueryChanged(q))),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Matches the search against what the user reads on the card: the variable
/// (in the current language), the device and the area.
bool _matches(DeviationAlert alert, String query, AlertsData data, AppLocalizations i18n) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return [
    alertVariable(i18n, alert.parameterName),
    alert.parameterName,
    data.deviceNames[alert.equipmentId],
    data.environmentNames[alert.environmentId],
  ].whereType<String>().any((text) => text.toLowerCase().contains(q));
}

int _count(AlertFilter filter, AlertSummary s) => switch (filter) {
  AlertFilter.open => s.open,
  AlertFilter.all => s.total,
  AlertFilter.unresolved => s.unresolved,
  AlertFilter.acknowledged => s.acknowledged,
  AlertFilter.resolved => s.resolved,
  AlertFilter.critical => s.critical,
};

/// Label, icon and tone of each filter, shared by the menu and the card.
final class _FilterStyle {
  const _FilterStyle(this.label, this.icon, this.tone);

  final String Function(AppLocalizations i18n) label;
  final IconData icon;
  final BadgeTone tone;

  static _FilterStyle of(AlertFilter filter) => switch (filter) {
    AlertFilter.open => _FilterStyle((i) => i.alertsOpen, Icons.report_problem_outlined, BadgeTone.warning),
    AlertFilter.all => _FilterStyle((i) => i.filterAll, Icons.list_alt, BadgeTone.neutral),
    AlertFilter.unresolved => _FilterStyle((i) => i.alertUnresolved, Icons.error_outline, BadgeTone.critical),
    AlertFilter.acknowledged => _FilterStyle((i) => i.alertAcknowledged, Icons.visibility_outlined, BadgeTone.info),
    AlertFilter.resolved => _FilterStyle((i) => i.alertResolved, Icons.task_alt, BadgeTone.success),
    AlertFilter.critical => _FilterStyle((i) => i.criticalOpen, Icons.crisis_alert, BadgeTone.critical),
  };
}
