import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/connection_badge.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/view_status.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/actuation_event.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/metric_reading.dart';
import '../../domain/entities/metric_threshold.dart';
import '../../domain/entities/monitored_metric.dart';
import '../../domain/entities/telemetry_window.dart';
import '../bloc/telemetry_dashboard_bloc.dart';
import '../widgets/telemetry_chart.dart';
import '../widgets/telemetry_labels.dart';

/// Conditions of an environment or a container from the phone (US: consult
/// conditions from the mobile app).
class TelemetryDashboardScreen extends StatefulWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  State<TelemetryDashboardScreen> createState() => _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState extends State<TelemetryDashboardScreen> with WidgetsBindingObserver {
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

  void _openHistory(BuildContext context) {
    final id = context.read<TelemetryDashboardBloc>().state.selectedDeviceId;
    context.push(id == null ? '/telemetry/history' : '/telemetry/history?deviceId=$id');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: i18n.telemetryTitle, subtitle: i18n.telemetrySubtitle),
        actions: [
          IconButton(
            tooltip: i18n.rawTelemetryLog,
            icon: const Icon(Icons.table_rows_outlined),
            onPressed: () => _openHistory(context),
          ),
        ],
      ),
      body: BlocBuilder<TelemetryDashboardBloc, TelemetryState>(
        builder: (context, state) => RemoteStateView<DeviceCatalog>(
          state: state.catalog,
          onRetry: () => context.read<TelemetryDashboardBloc>().add(const TelemetryStarted()),
          emptyIcon: Icons.sensors_off_outlined,
          emptyMessage: i18n.telemetryNoDevices,
          builder: (context, catalog) => RefreshIndicator(
            onRefresh: () async => context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested()),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _DeviceSelector(catalog: catalog, selectedId: state.selectedDeviceId),
                const SizedBox(height: AppSpacing.md),
                _SnapshotSection(state: state, onOpenHistory: () => _openHistory(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.catalog, required this.selectedId});

  final DeviceCatalog catalog;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return DropdownButtonFormField<int>(
      key: ValueKey(selectedId),
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(labelText: i18n.selectDevice, prefixIcon: const Icon(Icons.sensors_outlined)),
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
      onChanged: (id) {
        if (id != null) context.read<TelemetryDashboardBloc>().add(TelemetryDeviceSelected(id));
      },
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({required this.state, required this.onOpenHistory});

  final TelemetryState state;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final remote = state.snapshot;
    void retry() => context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested());
    if (remote.status.isLoading && remote.data == null) {
      return const SizedBox(height: 240, child: LoadingView());
    }
    final data = remote.data;
    if (data == null) {
      return SizedBox(height: 320, child: ErrorView(failure: remote.failure!, onRetry: retry));
    }
    final readings = data.readings;
    final deviations = data.deviations;
    final profile = data.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefreshingBar(visible: remote.refreshing),
        if (remote.failure != null) StaleDataNotice(failure: remote.failure!),
        _StatusRow(snapshot: data),
        SectionHeader(
          title: i18n.currentReadings,
          subtitle: profile == null
              ? i18n.noProfileConfigured
              : i18n.profileVersion('${profile.version}'),
        ),
        if (readings.isEmpty)
          InfoCard(child: Text(i18n.noReadings24h))
        else
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              for (final reading in readings)
                _ReadingCard(reading: reading, threshold: data.thresholdFor(reading.latest.metric)),
            ],
          ),
        if (data.chartMetrics.isNotEmpty) ...[
          SectionHeader(title: i18n.liveTelemetryStream, subtitle: i18n.liveTelemetryHint),
          _ChartCard(state: state, snapshot: data),
        ],
        SectionHeader(title: i18n.deviations24h, subtitle: i18n.deviationsHint),
        if (deviations.isEmpty)
          InfoCard(child: Text(i18n.noDeviations))
        else
          for (final measurement in deviations.take(5)) ...[
            _DeviationTile(measurement: measurement),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (data.target.containerMonitor) ...[
          SectionHeader(title: i18n.automaticActions, subtitle: i18n.automaticActionsHint),
          if (data.actuationsFailure != null)
            StaleDataNotice(failure: data.actuationsFailure!)
          else if (data.actuations.isEmpty)
            InfoCard(child: Text(i18n.noAutomaticActions))
          else
            for (final event in data.actuations.take(5)) ...[
              _ActuationTile(event: event),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onOpenHistory,
          icon: const Icon(Icons.table_rows_outlined),
          label: Text(i18n.rawTelemetryLog),
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
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final connection = snapshot.connection;
    final deviations = snapshot.deviations.length;
    final lastCommunication = connection.lastCommunicationAt == null
        ? i18n.neverCommunicated
        : Formatters.dateTime(connection.lastCommunicationAt, context.localeName);
    final tone = connection.isConnected ? BadgeTone.success : BadgeTone.warning;
    return ResponsiveGrid(
      minItemWidth: 150,
      children: [
        InfoCard(
          color: tone.background,
          borderColor: tone.foreground.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i18n.connectionStatus, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              ConnectionBadge(connected: connection.reachable),
              const SizedBox(height: AppSpacing.xs),
              Text('${i18n.lastCommunication}: $lastCommunication', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        InfoCard(
          color: deviations > 0 ? AppColors.criticalContainer : AppColors.surface,
          borderColor: deviations > 0 ? AppColors.critical.withValues(alpha: 0.3) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i18n.deviations24h, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    deviations > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: deviations > 0 ? AppColors.critical : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(i18n.eventsCount(deviations), style: theme.textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                i18n.updatedAt(Formatters.time(snapshot.fetchedAt, context.localeName)),
                style: theme.textTheme.bodySmall,
              ),
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
    TelemetryWindow.fifteenMinutes => context.i18n.window15m,
    TelemetryWindow.oneHour => context.i18n.window1h,
    TelemetryWindow.sixHours => context.i18n.window6h,
    TelemetryWindow.twentyFourHours => context.i18n.window24h,
  };

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<TelemetryDashboardBloc>();
    final metrics = snapshot.chartMetrics;
    final metric = state.chartMetric;
    final windows = state.availableWindows;
    final window = state.effectiveWindow;
    final threshold = metric == null ? null : snapshot.thresholdFor(metric);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (metrics.length > 1) ...[
            FilterChipBar<MonitoredMetric>(
              options: metrics,
              selected: metric ?? metrics.first,
              labelOf: (m) => m.label(i18n),
              onSelected: (m) => bloc.add(TelemetryMetricSelected(m)),
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
          TelemetryChart(
            points: state.chartSeries,
            threshold: threshold,
            unit: metric == null ? null : snapshot.unitFor(metric),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Legend(color: AppColors.chartLine, label: metric?.label(i18n) ?? '—'),
              _Legend(color: AppColors.chartWarning, label: i18n.stateWarning),
              _Legend(color: AppColors.chartCritical, label: i18n.stateCritical),
              if (threshold != null) ...[
                _Legend(color: AppColors.chartNormalRange, label: i18n.normalRange, dashed: true),
                _Legend(color: AppColors.chartCritical, label: i18n.criticalRange, dashed: true),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: dashed ? 3 : 12,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.smAll),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Text of a reading: number with unit, a detected motion or an RFID tag.
String readingText(BuildContext context, Measurement m) {
  final i18n = context.i18n;
  if (m.metric == MonitoredMetric.motion) return i18n.motionDetected;
  if (m.textValue != null && m.textValue!.isNotEmpty) return m.textValue!;
  if (m.value == null) return '—';
  return '${Formatters.number(m.value, context.localeName)} ${m.unit ?? ''}'.trim();
}

/// "Normal 2–8 °C · critical 0–10 °C" with the bounds that are configured.
String? rangeText(BuildContext context, MetricThreshold? threshold) {
  if (threshold == null) return null;
  final locale = context.localeName;
  final unit = threshold.unit ?? '';
  // An open bound reads as "≤ 300 lux" or "≥ 2 °C" instead of an infinity.
  String bounds(double? min, double? max) {
    final low = min == null ? null : Formatters.number(min, locale);
    final high = max == null ? null : Formatters.number(max, locale);
    final text = low == null ? '≤ $high' : (high == null ? '≥ $low' : '$low–$high');
    return '$text $unit'.trim();
  }
  final parts = <String>[
    if (threshold.normalMin != null || threshold.normalMax != null)
      context.i18n.normalRangeValue(bounds(threshold.normalMin, threshold.normalMax)),
    if (threshold.criticalMin != null || threshold.criticalMax != null)
      context.i18n.criticalRangeValue(bounds(threshold.criticalMin, threshold.criticalMax)),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, this.threshold});

  final MetricReading reading;
  final MetricThreshold? threshold;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final m = reading.latest;
    final range = rangeText(context, threshold);
    final name = m.metric.label(i18n, raw: m.rawMetric);
    return Semantics(
      label: '$name: ${readingText(context, m)}',
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(m.metric.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(readingText(context, m), style: AppTypography.metric),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (m.state != EnvironmentalState.unknown) StateBadge(state: m.state),
            if (range != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(range, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(Formatters.dateTime(m.measuredAt, context.localeName), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DeviationTile extends StatelessWidget {
  const _DeviationTile({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final m = measurement;
    final critical = m.state == EnvironmentalState.critical;
    final color = critical ? AppColors.critical : AppColors.warning;
    return InfoCard(
      color: (critical ? AppColors.criticalContainer : AppColors.warningContainer).withValues(alpha: 0.5),
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.metric.label(i18n, raw: m.rawMetric), style: Theme.of(context).textTheme.titleSmall),
                if (m.thresholdValue != null)
                  Text(
                    i18n.thresholdExceeded('${Formatters.number(m.thresholdValue, locale)} ${m.unit ?? ''}'.trim()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(Formatters.dateTime(m.measuredAt, locale), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StateBadge(state: m.state),
              const SizedBox(height: AppSpacing.xs),
              Text(
                readingText(context, m),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActuationTile extends StatelessWidget {
  const _ActuationTile({required this.event});

  final ActuationEvent event;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final trigger = event.triggerMetric == null
        ? null
        : '${event.triggerMetric!.label(i18n)} · ${event.triggerState?.label(i18n) ?? '—'}';
    return InfoCard(
      child: Row(
        children: [
          const Icon(Icons.settings_remote_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actuationLabel(i18n, event.action), style: theme.textTheme.titleSmall),
                if (trigger != null) Text(trigger, style: theme.textTheme.bodySmall),
                Text(Formatters.dateTime(event.occurredAt, context.localeName), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            label: event.executed ? i18n.actionExecuted : i18n.actionFailed,
            tone: event.executed ? BadgeTone.success : BadgeTone.critical,
          ),
        ],
      ),
    );
  }
}
