import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/view_status.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/telemetry.dart';
import '../bloc/telemetry_history_bloc.dart';

/// "Raw Telemetry Data Log" mockup.
class TelemetryHistoryPage extends StatelessWidget {
  const TelemetryHistoryPage({super.key});

  Future<void> _pickRange(BuildContext context, HistoryRange? current) async {
    final bloc = context.read<TelemetryHistoryBloc>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: current == null ? null : DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null) return;
    final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
    bloc.add(TelemetryHistoryRangeChanged(HistoryRange(from: picked.start, to: end)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rawTelemetryLog)),
      body: BlocBuilder<TelemetryHistoryBloc, TelemetryHistoryState>(
        builder: (context, state) => RemoteStateView<List<Equipment>>(
          state: state.equipments,
          onRetry: () => context.read<TelemetryHistoryBloc>().add(const TelemetryHistoryStarted()),
          emptyMessage: l10n.equipmentEmpty,
          builder: (context, equipments) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              PageHeader(title: l10n.rawTelemetryLog, subtitle: l10n.rawTelemetrySubtitle),
              const SizedBox(height: AppSpacing.md),
              _Filters(state: state, equipments: equipments, onPickRange: () => _pickRange(context, state.range)),
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
  const _Filters({required this.state, required this.equipments, required this.onPickRange});

  final TelemetryHistoryState state;
  final List<Equipment> equipments;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TelemetryHistoryBloc>();
    final locale = context.localeName;
    final range = state.range;
    final loading = state.points.status == ViewStatus.loading;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(state.selectedEquipmentId),
            value: state.selectedEquipmentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.selectEquipment),
            items: [
              for (final e in equipments)
                DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: loading
                ? null
                : (id) {
                    if (id != null) bloc.add(TelemetryHistoryEquipmentSelected(id));
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: loading ? null : onPickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              range == null
                  ? l10n.dateRangeAll
                  : '${Formatters.date(range.from, locale)} – ${Formatters.date(range.to, locale)}',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onlyAnomalies),
            value: state.onlyAnomalies,
            onChanged: (v) => bloc.add(TelemetryHistoryAnomaliesToggled(v)),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : () => bloc.add(const TelemetryHistoryFiltersCleared()),
                  child: Text(l10n.clearFilters),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : () => bloc.add(const TelemetryHistorySearchRequested()),
                  icon: const Icon(Icons.search),
                  label: Text(l10n.search),
                ),
              ),
            ],
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
          child: ErrorView(
            failure: remote.failure!,
            onRetry: () => bloc.add(const TelemetryHistorySearchRequested()),
          ),
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
          for (final p in items) ...[_HistoryTile(point: p), const SizedBox(height: AppSpacing.sm)],
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
  const _HistoryTile({required this.point});

  final TelemetryHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final anomaly = point.isAnomaly;
    return InfoCard(
      color: anomaly ? AppColors.criticalContainer.withValues(alpha: 0.5) : null,
      borderColor: anomaly ? AppColors.critical.withValues(alpha: 0.3) : null,
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
                    Text(point.parameterName, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              StatusBadge(
                label: anomaly ? l10n.bpmDeviation : l10n.normal,
                tone: anomaly ? BadgeTone.critical : BadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: KeyValue(
                  label: l10n.timestamp,
                  value: point.timestamp != null
                      ? Formatters.dateTime(point.timestamp, locale)
                      : (point.rawTimestamp ?? '—'),
                ),
              ),
              KeyValue(
                label: l10n.recordedValue,
                value: Formatters.number(point.recordedValue, locale),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
