import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
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
import '../bloc/telemetry_dashboard_bloc.dart';
import '../widgets/telemetry_chart.dart';
import '../widgets/telemetry_labels.dart';

class TelemetryDashboardPage extends StatefulWidget {
  const TelemetryDashboardPage({super.key});

  @override
  State<TelemetryDashboardPage> createState() => _TelemetryDashboardPageState();
}

class _TelemetryDashboardPageState extends State<TelemetryDashboardPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Stops polling while the app is in background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<TelemetryDashboardBloc>();
    if (state == AppLifecycleState.resumed) {
      bloc.add(const TelemetryPollingResumed());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      bloc.add(const TelemetryPollingPaused());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.telemetryTitle),
        actions: [
          IconButton(
            tooltip: l10n.rawTelemetryLog,
            icon: const Icon(Icons.table_rows_outlined),
            onPressed: () {
              final id = context.read<TelemetryDashboardBloc>().state.selectedEquipmentId;
              context.push(id == null ? '/telemetry/history' : '/telemetry/history?equipmentId=$id');
            },
          ),
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested()),
          ),
        ],
      ),
      body: BlocBuilder<TelemetryDashboardBloc, TelemetryState>(
        builder: (context, state) => RemoteStateView<List<Equipment>>(
          state: state.equipments,
          onRetry: () => context.read<TelemetryDashboardBloc>().add(const TelemetryStarted()),
          emptyIcon: Icons.sensors_off_outlined,
          emptyMessage: l10n.equipmentEmpty,
          builder: (context, equipments) => RefreshIndicator(
            onRefresh: () async =>
                context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested()),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(
                  title: l10n.telemetryTitle,
                  subtitle: l10n.telemetrySubtitle,
                  trailing: state.polling
                      ? StatusBadge(
                          label: l10n.liveUpdates,
                          tone: BadgeTone.brand,
                          icon: Icons.podcasts,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _EquipmentSelector(equipments: equipments, selectedId: state.selectedEquipmentId),
                const SizedBox(height: AppSpacing.md),
                _SnapshotSection(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentSelector extends StatelessWidget {
  const _EquipmentSelector({required this.equipments, required this.selectedId});

  final List<Equipment> equipments;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: ValueKey(selectedId),
      value: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.selectEquipment,
        prefixIcon: const Icon(Icons.precision_manufacturing_outlined),
      ),
      items: [
        for (final e in equipments)
          DropdownMenuItem(
            value: e.id,
            child: Text(e.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id != null) {
          context.read<TelemetryDashboardBloc>().add(TelemetryEquipmentSelected(id));
        }
      },
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({required this.state});

  final TelemetryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remote = state.snapshot;
    void retry() => context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested());
    if (remote.status.isLoading && remote.data == null) {
      return const SizedBox(height: 240, child: LoadingView());
    }
    final data = remote.data;
    if (data == null) {
      return SizedBox(
        height: 320,
        child: ErrorView(failure: remote.failure!, onRetry: retry),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefreshingBar(visible: remote.refreshing),
        if (remote.failure != null) StaleDataNotice(failure: remote.failure!),
        _StatusRow(snapshot: data),
        SectionHeader(title: l10n.liveTelemetryStream, subtitle: l10n.liveTelemetryHint),
        _ChartCard(state: state, snapshot: data),
        SectionHeader(
          title: l10n.currentReadings,
          subtitle: l10n.updatedAt(Formatters.time(data.fetchedAt, context.localeName)),
        ),
        if (data.readings.isEmpty)
          InfoCard(child: Text(l10n.noMeasurements))
        else
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              for (final r in data.readings)
                _ReadingCard(reading: r, limit: data.limitFor(r.latest.parameterName)),
            ],
          ),
        SectionHeader(
          title: l10n.activeTelemetryEvents,
          subtitle: l10n.anomaliesLast24h,
        ),
        if (data.historyFailure != null)
          StaleDataNotice(failure: data.historyFailure!)
        else if (data.anomalies.isEmpty)
          InfoCard(child: Text(l10n.noAnomalies))
        else
          for (final a in data.anomalies.take(5)) ...[
            _AnomalyTile(point: a, unit: data.unitFor(a.parameterName)),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.push('/telemetry/history?equipmentId=${data.equipmentId}'),
          icon: const Icon(Icons.table_rows_outlined),
          label: Text(l10n.rawTelemetryLog),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = snapshot.status;
    final anomalies = snapshot.anomalies.length;
    final heartbeat = status.lastHeartbeat != null
        ? Formatters.dateTime(status.lastHeartbeat, context.localeName)
        : (status.rawLastHeartbeat ?? '—');
    return ResponsiveGrid(
      minItemWidth: 150,
      children: [
        InfoCard(
          color: status.currentStatus.tone.background,
          borderColor: status.currentStatus.tone.foreground.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.connectionStatus.toUpperCase(), style: AppTypography.overline),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(status.currentStatus.tone.icon, color: status.currentStatus.tone.foreground),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      status.currentStatus.label(l10n),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              OnlineBadge(online: status.isOnline),
              const SizedBox(height: AppSpacing.xs),
              Text('${l10n.lastHeartbeat}: $heartbeat', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        InfoCard(
          color: anomalies > 0 ? AppColors.criticalContainer : AppColors.surface,
          borderColor: anomalies > 0 ? AppColors.critical.withValues(alpha: 0.3) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.detectedAnomalies.toUpperCase(), style: AppTypography.overline),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    anomalies > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: anomalies > 0 ? AppColors.critical : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.eventsCount(anomalies),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.anomaliesLast24h, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.state, required this.snapshot});

  final TelemetryState state;
  final TelemetrySnapshot snapshot;

  String _windowLabel(BuildContext context, TelemetryWindow w) => switch (w) {
    TelemetryWindow.fifteenMinutes => context.l10n.window15m,
    TelemetryWindow.oneHour => context.l10n.window1h,
    TelemetryWindow.sixHours => context.l10n.window6h,
    TelemetryWindow.twentyFourHours => context.l10n.window24h,
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TelemetryDashboardBloc>();
    final parameters = snapshot.chartParameters;
    final parameter = state.chartParameter;
    final windows = state.availableWindows;
    final window = state.effectiveWindow;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parameters.length > 1) ...[
            FilterChipBar<String>(
              options: parameters,
              selected: parameter ?? parameters.first,
              labelOf: (p) => p,
              onSelected: (p) => bloc.add(TelemetryParameterSelected(p)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (windows.length > 1 && window != null) ...[
            FilterChipBar<TelemetryWindow>(
              options: windows,
              selected: window,
              labelOf: (w) => _windowLabel(context, w),
              onSelected: (w) => bloc.add(TelemetryWindowSelected(w)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (snapshot.historyFailure != null)
            StaleDataNotice(failure: snapshot.historyFailure!)
          else
            TelemetryChart(
              points: state.chartSeries,
              limit: parameter == null ? null : snapshot.limitFor(parameter),
              unit: parameter == null ? null : snapshot.unitFor(parameter),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Legend(color: AppColors.chartLine, label: parameter ?? '—'),
              _Legend(color: AppColors.chartAnomaly, label: context.l10n.anomaly),
              if (parameter != null && snapshot.limitFor(parameter) != null)
                _Legend(color: AppColors.chartLimit, label: context.l10n.bpmLimits),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.smAll),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, this.limit});

  final ParameterReading reading;
  final BpmParameterConfig? limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final m = reading.latest;
    final within = limit?.isWithin(m.value);
    final time = m.timestamp != null ? Formatters.dateTime(m.timestamp, locale) : (m.rawTimestamp ?? '—');
    return Semantics(
      label: '${m.parameterName}: ${Formatters.number(m.value, locale)} ${m.unit ?? ''}',
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(parameterIcon(m.parameterName), size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    m.parameterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: Formatters.number(m.value, locale), style: AppTypography.metric),
                    TextSpan(
                      text: ' ${m.unit ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (limit != null)
              Text(
                l10n.targetRange(
                  Formatters.number(limit!.minValue, locale),
                  Formatters.number(limit!.maxValue, locale),
                  limit!.unit ?? m.unit ?? '',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (within != null) ...[
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(
                label: within ? l10n.withinLimits : l10n.outOfLimits,
                tone: within ? BadgeTone.success : BadgeTone.critical,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AnomalyTile extends StatelessWidget {
  const _AnomalyTile({required this.point, this.unit});

  final TelemetryHistoryPoint point;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    return InfoCard(
      color: AppColors.criticalContainer.withValues(alpha: 0.5),
      borderColor: AppColors.critical.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.parameter.toUpperCase(), style: AppTypography.overline),
                Text(point.parameterName, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  point.timestamp != null
                      ? Formatters.dateTime(point.timestamp, locale)
                      : (point.rawTimestamp ?? '—'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: l10n.bpmDeviation, tone: BadgeTone.critical),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Formatters.number(point.recordedValue, locale)} ${unit ?? ''}',
                style: const TextStyle(
                  color: AppColors.critical,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
