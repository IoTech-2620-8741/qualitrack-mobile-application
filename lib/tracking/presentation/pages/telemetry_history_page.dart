import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/view_status.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../domain/telemetry.dart';
import '../bloc/telemetry_dashboard_bloc.dart';
import '../bloc/telemetry_history_bloc.dart';
import '../widgets/telemetry_labels.dart';
import 'telemetry_dashboard_page.dart';

/// "Raw Telemetry Data Log" mockup: readings of one device in a period of up
/// to 31 days.
class TelemetryHistoryPage extends StatelessWidget {
  const TelemetryHistoryPage({super.key});

  Future<void> _pickRange(BuildContext context, HistoryRange current) async {
    final bloc = context.read<TelemetryHistoryBloc>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: current.from, end: current.to.isAfter(now) ? now : current.to),
      helpText: l10n.periodMax31Days,
    );
    if (picked == null) return;
    final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
    final range = HistoryRange(from: picked.start, to: end.isAfter(now) ? now : end);
    if (!range.isValid) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.periodMax31Days)));
      return;
    }
    bloc.add(TelemetryHistoryRangeChanged(range));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rawTelemetryLog)),
      body: BlocBuilder<TelemetryHistoryBloc, TelemetryHistoryState>(
        builder: (context, state) => RemoteStateView<DeviceCatalog>(
          state: state.catalog,
          onRetry: () => context.read<TelemetryHistoryBloc>().add(const TelemetryHistoryStarted()),
          emptyIcon: Icons.sensors_off_outlined,
          emptyMessage: l10n.telemetryNoDevices,
          builder: (context, catalog) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              PageHeader(title: l10n.rawTelemetryLog, subtitle: l10n.rawTelemetrySubtitle),
              const SizedBox(height: AppSpacing.md),
              _Filters(state: state, catalog: catalog, onPickRange: () => _pickRange(context, state.range)),
              const SizedBox(height: AppSpacing.md),
              _Results(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.catalog, required this.onPickRange});

  final TelemetryHistoryState state;
  final DeviceCatalog catalog;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TelemetryHistoryBloc>();
    final locale = context.localeName;
    final loading = state.points.status == ViewStatus.loading;
    final metrics = state.metrics;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(state.selectedDeviceId),
            initialValue: state.selectedDeviceId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.selectDevice),
            items: [
              for (final device in catalog.devices)
                DropdownMenuItem(
                  value: device.id,
                  child: Text(
                    '${device.name} · ${catalog.environmentOf(device)?.name ?? '—'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: loading
                ? null
                : (id) {
                    if (id != null) bloc.add(TelemetryHistoryDeviceSelected(id));
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: loading ? null : onPickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              '${Formatters.dateTime(state.range.from, locale)} – ${Formatters.dateTime(state.range.to, locale)}',
            ),
          ),
          if (metrics.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            FilterChipBar<MonitoredMetric?>(
              options: [null, ...metrics],
              selected: state.metric,
              labelOf: (m) => m == null ? l10n.filterAll : m.label(l10n),
              onSelected: (m) => bloc.add(TelemetryHistoryMetricChanged(m)),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onlyDeviations),
            value: state.onlyDeviations,
            onChanged: (v) => bloc.add(TelemetryHistoryDeviationsToggled(v)),
          ),
          FilledButton.icon(
            onPressed: loading ? null : () => bloc.add(const TelemetryHistorySearchRequested()),
            icon: const Icon(Icons.search),
            label: Text(l10n.search),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final TelemetryHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TelemetryHistoryBloc>();
    final remote = state.points;
    switch (remote.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const SizedBox(height: 200, child: LoadingView());
      case ViewStatus.failure:
        return SizedBox(
          height: 300,
          child: ErrorView(failure: remote.failure!, onRetry: () => bloc.add(const TelemetryHistorySearchRequested())),
        );
      case ViewStatus.empty:
        return SizedBox(height: 220, child: EmptyView(title: l10n.noHistoryInRange));
      case ViewStatus.success:
        break;
    }
    final items = state.pageItems;
    final total = state.filtered.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.liveEntries(total)),
        if (items.isEmpty)
          SizedBox(height: 160, child: EmptyView(title: l10n.noResults))
        else
          for (final m in items) ...[_HistoryTile(measurement: m), const SizedBox(height: AppSpacing.sm)],
        if (state.pageCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.previous,
                onPressed: state.page > 0 ? () => bloc.add(TelemetryHistoryPageChanged(state.page - 1)) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(l10n.pageOf(state.page + 1, state.pageCount)),
              IconButton(
                tooltip: l10n.next,
                onPressed: state.page + 1 < state.pageCount
                    ? () => bloc.add(TelemetryHistoryPageChanged(state.page + 1))
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = measurement;
    final critical = m.state == EnvironmentalState.critical;
    final deviation = m.state.isDeviation;
    final color = critical ? AppColors.critical : AppColors.warning;
    return InfoCard(
      color: deviation
          ? (critical ? AppColors.criticalContainer : AppColors.warningContainer).withValues(alpha: 0.5)
          : null,
      borderColor: deviation ? color.withValues(alpha: 0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.parameter.toUpperCase(), style: AppTypography.overline),
                    Text(m.metric.label(l10n, raw: m.rawMetric), style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              if (m.state != EnvironmentalState.unknown) StateBadge(state: m.state),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: KeyValue(label: l10n.timestamp, value: Formatters.dateTime(m.measuredAt, context.localeName)),
              ),
              KeyValue(label: l10n.recordedValue, value: readingText(context, m)),
            ],
          ),
        ],
      ),
    );
  }
}
