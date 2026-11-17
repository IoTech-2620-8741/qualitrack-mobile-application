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
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/view_status.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/pressable_card.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../equipment/api/index.dart';
import '../../domain/entities/actuation_event.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/metric_reading.dart';
import '../../domain/entities/metric_threshold.dart';
import '../../domain/entities/monitored_metric.dart';
import '../../domain/entities/telemetry_window.dart';
import '../bloc/telemetry_dashboard_bloc.dart';
import '../widgets/reading_range_bar.dart';
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
          // Short help, where the terms are used (states, ranges, review).
          IconButton(
            key: const Key('telemetry.help'),
            tooltip: i18n.telemetryHelp,
            icon: const Icon(Icons.help_outline),
            onPressed: () => showTelemetryHelp(context),
          ),
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

/// A short sheet that explains the states, the chart and the connection,
/// focused on reading this screen.
Future<void> showTelemetryHelp(BuildContext context) {
  final i18n = context.i18n;
  final text = Theme.of(context).textTheme;
  Widget item(Widget leading, String title, String body) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(width: 96, child: Align(alignment: Alignment.centerLeft, child: leading)),
    title: title.isEmpty ? null : Text(title, style: text.titleSmall),
    subtitle: Text(body, style: text.bodyMedium),
  );
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (sheet) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text(i18n.telemetryHelp, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            item(const StateBadge(state: EnvironmentalState.normal), '', i18n.telemetryHelpNormal),
            item(const StateBadge(state: EnvironmentalState.warning), '', i18n.telemetryHelpWarning),
            item(const StateBadge(state: EnvironmentalState.critical), '', i18n.telemetryHelpCritical),
            const Divider(),
            item(const Icon(Icons.show_chart, color: AppColors.chartNormalRange), i18n.normalRange, i18n.telemetryHelpRange),
            item(const ConnectionBadge(connected: false), '', i18n.telemetryHelpReview),
            item(const Icon(Icons.table_rows_outlined, color: AppColors.primary), i18n.rawTelemetryLog, i18n.telemetryHelpLog),
          ],
        ),
  );
}

/// The device whose telemetry is shown, as one card with its type, name,
/// environment and status. Tapping it opens [_DevicePickerSheet] with every
/// device grouped by environment, so one component serves from 2 devices to
/// the 15 an Edge Gateway can have.
class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.catalog, required this.selectedId});

  final DeviceCatalog catalog;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final device = catalog.devices.where((d) => d.id == selectedId).firstOrNull;
    final environment = device == null ? null : catalog.environmentOf(device)?.name;
    final canChange = catalog.devices.length > 1;
    return PressableCard(
      key: const Key('telemetry.deviceSelector'),
      borderRadius: AppRadius.xlAll,
      onTap: canChange ? () => _showDevicePicker(context, catalog, selectedId) : null,
      semanticLabel: [
        '${i18n.selectDevice}: ${device?.name ?? '—'}',
        if (environment != null) environment,
        if (device != null) _deviceStatusLabel(i18n, device.status),
      ].join(', '),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _DeviceIcon(device: device),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device?.name ?? i18n.selectDevice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      if (device != null) ...[
                        _DeviceStatusIcon(status: device.status),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          environment ?? i18n.notLocated,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canChange) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.unfold_more, color: AppColors.primaryDark),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showDevicePicker(BuildContext context, DeviceCatalog catalog, int? selectedId) {
  final bloc = context.read<TelemetryDashboardBloc>();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => _DevicePickerSheet(
      catalog: catalog,
      selectedId: selectedId,
      onSelected: (id) {
        Navigator.of(sheet).pop();
        bloc.add(TelemetryDeviceSelected(id));
      },
    ),
  );
}

/// Every device grouped by environment, in the order of the environments, and
/// then the devices that are not located yet.
class _DevicePickerSheet extends StatelessWidget {
  const _DevicePickerSheet({required this.catalog, required this.selectedId, required this.onSelected});

  final DeviceCatalog catalog;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  List<(String, List<Equipment>)> _groups(AppLocalizations i18n) {
    final groups = <(String, List<Equipment>)>[];
    for (final environment in catalog.environments) {
      final devices = catalog.devices.where((d) => d.environmentId == environment.id).toList();
      if (devices.isNotEmpty) groups.add((environment.name, devices));
    }
    final notLocated = catalog.devices.where((d) => catalog.environmentOf(d) == null).toList();
    if (notLocated.isNotEmpty) groups.add((i18n.notLocated, notLocated));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(i18n.chooseDevice, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final (environment, devices) in _groups(i18n)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
            // Read as written, not letter by letter.
            child: Semantics(
              header: true,
              label: environment,
              excludeSemantics: true,
              child: Text(environment.toUpperCase(), style: AppTypography.overline),
            ),
          ),
          for (final device in devices)
            _DeviceOption(device: device, selected: device.id == selectedId, onTap: () => onSelected(device.id)),
        ],
      ],
    );
  }
}

class _DeviceOption extends StatelessWidget {
  const _DeviceOption({required this.device, required this.selected, required this.onTap});

  final Equipment device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    // The status is written only when it needs attention; the icon shows it always.
    final details = [
      _deviceTypeLabel(i18n, device),
      if (device.status != EquipmentStatus.operational) _deviceStatusLabel(i18n, device.status),
    ].whereType<String>().join(' · ');
    return ListTile(
      key: ValueKey('telemetry.device.${device.id}'),
      selected: selected,
      selectedTileColor: AppColors.primaryContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Icon(_deviceIcon(device), color: AppColors.primaryDark),
      title: Text(device.name),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DeviceStatusIcon(status: device.status),
          if (selected) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.check, color: AppColors.primaryDark),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

/// The type of the device on a tinted square: a container or the environment.
class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({required this.device});

  final Equipment? device;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.lgAll),
      child: Icon(_deviceIcon(device), color: AppColors.primaryDark),
    );
  }
}

/// The equipment status as an icon of its tone, so it is not told by color
/// alone; screen readers get the status in the label of the card or the row.
class _DeviceStatusIcon extends StatelessWidget {
  const _DeviceStatusIcon({required this.status});

  final EquipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = _deviceStatusTone(status);
    return Icon(tone.icon, size: 16, color: tone == BadgeTone.neutral ? AppColors.textMuted : tone.foreground);
  }
}

IconData _deviceIcon(Equipment? device) =>
    (device?.isContainerMonitor ?? false) ? Icons.kitchen_outlined : Icons.sensors_outlined;

String? _deviceTypeLabel(AppLocalizations i18n, Equipment device) => switch (device.deviceType) {
  IotDeviceType.containerMonitor => i18n.containerMonitor,
  IotDeviceType.environmentalDevice => i18n.environmentalDevice,
  null => null,
};

BadgeTone _deviceStatusTone(EquipmentStatus status) => switch (status) {
  EquipmentStatus.operational => BadgeTone.success,
  EquipmentStatus.maintenance => BadgeTone.warning,
  EquipmentStatus.outOfService => BadgeTone.critical,
  EquipmentStatus.inactive || EquipmentStatus.unknown => BadgeTone.neutral,
};

String _deviceStatusLabel(AppLocalizations i18n, EquipmentStatus status) => switch (status) {
  EquipmentStatus.operational => i18n.equipmentOperational,
  EquipmentStatus.maintenance => i18n.equipmentMaintenance,
  EquipmentStatus.outOfService => i18n.equipmentOutOfService,
  EquipmentStatus.inactive => i18n.inactive,
  EquipmentStatus.unknown => i18n.unknown,
};

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
    final profile = data.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefreshingBar(visible: remote.refreshing),
        if (remote.failure != null) StaleDataNotice(failure: remote.failure!),
        _StatusRow(snapshot: data),
        // Without readings there is nothing to chart or evaluate: one message
        // instead of several empty sections.
        if (readings.isEmpty) ...[
          SectionHeader(title: i18n.currentReadings),
          EmptyNotice(icon: Icons.sensors_off_outlined, message: i18n.noReadings24h),
        ] else ...[
          // The profile version is a technical detail; only a missing profile
          // matters to the user.
          SectionHeader(
            title: i18n.currentReadings,
            subtitle: profile == null ? i18n.noProfileConfigured : null,
            trailing: _ReadingsTime(readings: readings),
          ),
          _ReadingsList(snapshot: data),
          if (data.chartMetrics.isNotEmpty) ...[
            SectionHeader(title: i18n.liveTelemetryStream, subtitle: i18n.liveTelemetryHint),
            _ChartCard(state: state, snapshot: data),
          ],
        ],
        // Automatic actions show up without readings only when there are some.
        if (data.target.containerMonitor && (readings.isNotEmpty || data.actuations.isNotEmpty)) ...[
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
        : relativeTime(context, connection.lastCommunicationAt);
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
                  Expanded(
                    child: Text(
                      deviations == 1 ? i18n.eventsCountOne : i18n.eventsCount(deviations),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                updatedText(context, snapshot.fetchedAt),
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
                _Legend(color: TelemetryChart.normalBand, label: i18n.normalRange),
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
  String bounds(double? min, double? max) => Formatters.range(min, max, threshold.unit, locale);
  final parts = <String>[
    if (threshold.normalMin != null || threshold.normalMax != null)
      context.i18n.normalRangeValue(bounds(threshold.normalMin, threshold.normalMax)),
    if (threshold.criticalMin != null || threshold.criticalMax != null)
      context.i18n.criticalRangeValue(bounds(threshold.criticalMin, threshold.criticalMax)),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// When the newest reading was taken, once for the whole list.
class _ReadingsTime extends StatelessWidget {
  const _ReadingsTime({required this.readings});

  final List<MetricReading> readings;

  @override
  Widget build(BuildContext context) {
    final newest = _newestTime(readings);
    if (newest == null) return const SizedBox.shrink();
    return Tooltip(
      message: Formatters.dateTime(newest, context.localeName),
      child: Text(relativeTime(context, newest), style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

DateTime? _newestTime(List<MetricReading> readings) {
  DateTime? newest;
  for (final reading in readings) {
    final at = reading.latest.measuredAt;
    if (at != null && (newest == null || at.isAfter(newest))) newest = at;
  }
  return newest;
}

/// The latest reading of every metric in one card, a row each.
class _ReadingsList extends StatelessWidget {
  const _ReadingsList({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final readings = snapshot.readings;
    final newest = _newestTime(readings);
    final sharedTime = newest == null ? null : relativeTime(context, newest);
    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, reading) in readings.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _ReadingRow(
              reading: reading,
              threshold: snapshot.thresholdFor(reading.latest.metric),
              sharedTime: sharedTime,
            ),
          ],
        ],
      ),
    );
  }
}

/// One metric: its name, value and state, a bar with its zones and the mark of
/// the reading, and its ranges written below. A reading out of range tints its
/// row, as the card did before.
class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading, required this.threshold, required this.sharedTime});

  final MetricReading reading;
  final MetricThreshold? threshold;

  /// Time shown next to the title of the list; the row repeats its own time
  /// only when it is a different one.
  final String? sharedTime;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final m = reading.latest;
    final name = m.metric.label(i18n, raw: m.rawMetric);
    final value = readingText(context, m);
    final range = rangeText(context, threshold);
    final evaluated = m.state != EnvironmentalState.unknown;
    final outOfRange = m.state.isDeviation;
    final tone = m.state.tone;
    final limits = threshold;
    final scale = limits != null && m.isNumeric ? ReadingRangeScale.of(limits, m.value!) : null;
    final time = m.measuredAt == null ? null : relativeTime(context, m.measuredAt);
    final ownTime = time == sharedTime ? null : time;
    return Semantics(
      label: [name, value, if (evaluated) m.state.label(i18n), if (range != null) range, if (ownTime != null) ownTime]
          .join(', '),
      excludeSemantics: true,
      child: ColoredBox(
        color: outOfRange ? tone.background : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(m.metric.icon, size: 20, color: outOfRange ? tone.foreground : AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // A long text value, such as an RFID tag, shrinks instead of
                  // pushing the name out.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: outOfRange ? tone.foreground : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (evaluated) ...[
                    const SizedBox(width: AppSpacing.sm),
                    StateBadge(state: m.state),
                  ],
                ],
              ),
              if (scale != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ReadingRangeBar(
                  key: ValueKey('telemetry.rangeBar.${m.rawMetric}'),
                  scale: scale,
                  state: m.state,
                ),
              ],
              if (range != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(range, style: theme.textTheme.bodySmall),
              ],
              if (ownTime != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Tooltip(
                  message: Formatters.dateTime(m.measuredAt, context.localeName),
                  child: Text(ownTime, style: theme.textTheme.bodySmall),
                ),
              ],
            ],
          ),
        ),
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
