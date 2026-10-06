import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
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

/// Conditions of an environment or a container from the phone (US: consult
/// conditions from the mobile app).
class TelemetryDashboardPage extends StatefulWidget {
  const TelemetryDashboardPage({super.key});

  @override
  State<TelemetryDashboardPage> createState() => _TelemetryDashboardPageState();
}

class _TelemetryDashboardPageState extends State<TelemetryDashboardPage> with WidgetsBindingObserver {
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.telemetryTitle),
        actions: [
          IconButton(
            tooltip: l10n.rawTelemetryLog,
            icon: const Icon(Icons.table_rows_outlined),
            onPressed: () => _openHistory(context),
          ),
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested()),
          ),
        ],
      ),
      body: BlocBuilder<TelemetryDashboardBloc, TelemetryState>(
        builder: (context, state) => RemoteStateView<DeviceCatalog>(
          state: state.catalog,
          onRetry: () => context.read<TelemetryDashboardBloc>().add(const TelemetryStarted()),
          emptyIcon: Icons.sensors_off_outlined,
          emptyMessage: l10n.telemetryNoDevices,
          builder: (context, catalog) => RefreshIndicator(
            onRefresh: () async => context.read<TelemetryDashboardBloc>().add(const TelemetryRefreshRequested()),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(
                  title: l10n.telemetryTitle,
                  subtitle: l10n.telemetrySubtitle,
                  trailing: state.polling
                      ? StatusBadge(label: l10n.liveUpdates, tone: BadgeTone.brand, icon: Icons.podcasts)
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
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
    final l10n = context.l10n;
    return DropdownButtonFormField<int>(
      key: ValueKey(selectedId),
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.selectDevice, prefixIcon: const Icon(Icons.sensors_outlined)),
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
    final l10n = context.l10n;
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
          title: l10n.currentReadings,
          subtitle: profile == null
              ? l10n.noProfileConfigured
              : l10n.profileVersion('${profile.version}'),
        ),
        if (readings.isEmpty)
          InfoCard(child: Text(l10n.noReadings24h))
        else
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              for (final reading in readings)
                _ReadingCard(reading: reading, threshold: data.thresholdFor(reading.latest.metric)),
            ],
          ),
        if (data.chartMetrics.isNotEmpty) ...[
          SectionHeader(title: l10n.liveTelemetryStream, subtitle: l10n.liveTelemetryHint),
          _ChartCard(state: state, snapshot: data),
        ],
        SectionHeader(title: l10n.deviations24h, subtitle: l10n.deviationsHint),
        if (deviations.isEmpty)
          InfoCard(child: Text(l10n.noDeviations))
        else
          for (final measurement in deviations.take(5)) ...[
            _DeviationTile(measurement: measurement),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (data.target.containerMonitor) ...[
          SectionHeader(title: l10n.automaticActions, subtitle: l10n.automaticActionsHint),
          if (data.actuationsFailure != null)
            StaleDataNotice(failure: data.actuationsFailure!)
          else if (data.actuations.isEmpty)
            InfoCard(child: Text(l10n.noAutomaticActions))
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
    final theme = Theme.of(context);
    final connection = snapshot.connection;
    final deviations = snapshot.deviations.length;
    final lastCommunication = connection.lastCommunicationAt == null
        ? l10n.neverCommunicated
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
              Text(l10n.connectionStatus.toUpperCase(), style: AppTypography.overline),
              const SizedBox(height: AppSpacing.xs),
              ConnectionBadge(connection: connection),
              const SizedBox(height: AppSpacing.xs),
              Text('${l10n.lastCommunication}: $lastCommunication', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        InfoCard(
          color: deviations > 0 ? AppColors.criticalContainer : AppColors.surface,
          borderColor: deviations > 0 ? AppColors.critical.withValues(alpha: 0.3) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deviations24h.toUpperCase(), style: AppTypography.overline),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    deviations > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: deviations > 0 ? AppColors.critical : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(l10n.eventsCount(deviations), style: theme.textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.updatedAt(Formatters.time(snapshot.fetchedAt, context.localeName)),
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
    TelemetryWindow.fifteenMinutes => context.l10n.window15m,
    TelemetryWindow.oneHour => context.l10n.window1h,
    TelemetryWindow.sixHours => context.l10n.window6h,
    TelemetryWindow.twentyFourHours => context.l10n.window24h,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              labelOf: (m) => m.label(l10n),
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
              _Legend(color: AppColors.chartLine, label: metric?.label(l10n) ?? '—'),
              _Legend(color: AppColors.chartWarning, label: l10n.stateWarning),
              _Legend(color: AppColors.chartCritical, label: l10n.stateCritical),
              if (threshold != null) ...[
                _Legend(color: AppColors.chartNormalRange, label: l10n.normalRange, dashed: true),
                _Legend(color: AppColors.chartCritical, label: l10n.criticalRange, dashed: true),
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
  final l10n = context.l10n;
  if (m.metric == MonitoredMetric.motion) return l10n.motionDetected;
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
      context.l10n.normalRangeValue(bounds(threshold.normalMin, threshold.normalMax)),
    if (threshold.criticalMin != null || threshold.criticalMax != null)
      context.l10n.criticalRangeValue(bounds(threshold.criticalMin, threshold.criticalMax)),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, this.threshold});

  final MetricReading reading;
  final MetricThreshold? threshold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final m = reading.latest;
    final range = rangeText(context, threshold);
    final name = m.metric.label(l10n, raw: m.rawMetric);
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
    final l10n = context.l10n;
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
                Text(m.metric.label(l10n, raw: m.rawMetric), style: Theme.of(context).textTheme.titleSmall),
                if (m.thresholdValue != null)
                  Text(
                    l10n.thresholdExceeded('${Formatters.number(m.thresholdValue, locale)} ${m.unit ?? ''}'.trim()),
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trigger = event.triggerMetric == null
        ? null
        : '${event.triggerMetric!.label(l10n)} · ${event.triggerState?.label(l10n) ?? '—'}';
    return InfoCard(
      child: Row(
        children: [
          const Icon(Icons.settings_remote_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actuationLabel(l10n, event.action), style: theme.textTheme.titleSmall),
                if (trigger != null) Text(trigger, style: theme.textTheme.bodySmall),
                Text(Formatters.dateTime(event.occurredAt, context.localeName), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            label: event.executed ? l10n.actionExecuted : l10n.actionFailed,
            tone: event.executed ? BadgeTone.success : BadgeTone.critical,
          ),
        ],
      ),
    );
  }
}
