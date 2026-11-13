import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/connection_badge.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../compliance/api/index.dart';
import '../../../reporting/api/index.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../common/presentation/widgets/secondary_tabs.dart';
import '../../domain/entities/bpm_parameter_config.dart';
import '../../domain/entities/maintenance_record.dart';
import '../bloc/equipment_detail_bloc.dart';
import '../widgets/equipment_labels.dart';

class EquipmentDetailScreen extends StatelessWidget {
  const EquipmentDetailScreen({super.key, required this.currentUserId});

  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<EquipmentDetailBloc>().add(const EquipmentDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<EquipmentDetailBloc, RemoteState<EquipmentDetail>>(
          builder: (context, state) {
            final e = state.data?.equipment;
            return AppBarTitle(
              title: e?.name ?? i18n.equipmentDetail,
              subtitle: e == null ? null : [e.typeLabel(i18n), e.model].whereType<String>().join(' · '),
            );
          },
        ),
      ),
      body: BlocBuilder<EquipmentDetailBloc, RemoteState<EquipmentDetail>>(
        builder: (context, state) => RemoteStateView<EquipmentDetail>(
          state: state,
          onRetry: reload,
          builder: (context, detail) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: _DetailBody(detail: detail, currentUserId: currentUserId),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.currentUserId});

  final EquipmentDetail detail;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final e = detail.equipment;
    final connection = detail.connection;
    String person(int userId) => userId == currentUserId ? i18n.you : (detail.people[userId] ?? i18n.userNumber(userId));
    // Most important first: for an IoT device, whether it is connected and
    // how its variables behaved come before the specs (model, serial,
    // firmware), which are looked up rarely.
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (e.isIotDevice) ...[
          InfoCard(
            title: i18n.connectionStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: ConnectionBadge(connected: connection?.reachable)),
                if (connection != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${i18n.lastCommunication}: ${connection.lastCommunicationAt == null ? i18n.neverCommunicated : Formatters.dateTime(connection.lastCommunicationAt, locale)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (e.environmentId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/telemetry?deviceId=${e.id}'),
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: Text(i18n.viewTelemetry),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard<DeviationTrend>(
            title: i18n.deviationIndicators7d,
            section: detail.trends,
            emptyMessage: i18n.noReadingsInPeriod,
            itemBuilder: (context, t) {
              final percent = t.timeInRangePercent;
              return SectionRow(
                leading: Icon(_trendIcon(t.direction)),
                title: alertVariable(i18n, t.parameterName),
                subtitle: i18n.deviationsSummary(t.deviationCount, t.criticalDeviationCount),
                trailing: StatusBadge(
                  label: percent == null ? '—' : i18n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
                  tone: _severityTone(t.severity),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        InfoCard(
          title: i18n.generalInformation,
          child: DetailList(
            children: [
              DetailRow(
                label: i18n.status,
                value: e.statusLabel(i18n),
                valueWidget: StatusBadge(label: e.statusLabel(i18n), tone: e.status.tone),
              ),
              DetailRow(label: i18n.environment, value: detail.environmentName ?? i18n.notLocated),
              DetailRow(label: i18n.type, value: e.typeLabel(i18n) ?? '—'),
              DetailRow(label: i18n.model, value: e.model ?? '—'),
              DetailRow(label: i18n.serialNumber, value: e.serialNumber ?? '—'),
              if (e.deviceType != null) DetailRow(label: i18n.iotRole, value: e.deviceType!.label(i18n)),
              if (e.sensorExternalId != null) DetailRow(label: i18n.deviceIdentifier, value: e.sensorExternalId!),
              if (e.firmwareVersion != null) DetailRow(label: i18n.firmware, value: e.firmwareVersion!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // An Edge Gateway has no process parameters, so no BPM limits.
        if (!e.isEdgeGateway) ...[
          SectionCard<BpmParameterConfig>(
            title: i18n.bpmLimits,
            section: detail.bpmConfigs,
            emptyMessage: i18n.bpmLimitsEmpty,
            itemBuilder: (context, c) => SectionRow(
              title: c.parameterName,
              trailing: Text(
                '${Formatters.number(c.minValue, locale)} – ${Formatters.number(c.maxValue, locale)} ${c.unit ?? ''}'.trim(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        // The three history lists are alternative views of the same
        // equipment, so they share one place behind secondary tabs.
        SecondaryTabs(
          tabs: [
            SecondaryTab(label: i18n.tabMaintenance, builder: (context) => _maintenance(context, locale)),
            SecondaryTab(label: i18n.tabEvents, builder: (context) => _events(context, locale)),
            SecondaryTab(label: i18n.tabAudit, builder: (context) => _audit(context, locale, person)),
          ],
        ),
      ],
    );
  }

  Widget _maintenance(BuildContext context, String locale) => SectionCard<MaintenanceRecord>(
          section: detail.maintenance,
          emptyMessage: context.i18n.maintenanceEmpty,
          itemBuilder: (context, m) => SectionRow(
            title: codeLabel(context.i18n, m.type),
            subtitle: [m.description, m.technicianName].whereType<String>().join(' · '),
            trailing: Text(m.maintenanceDate != null ? Formatters.date(m.maintenanceDate, locale) : (m.rawDate ?? '—')),
          ),
        );

  Widget _events(BuildContext context, String locale) => SectionCard<ComplianceEvent>(
          section: detail.events,
          maxItems: 10,
          itemBuilder: (context, ev) => SectionRow(
            title: codeLabel(context.i18n, ev.eventType),
            subtitle: ev.description,
            trailing: Text(
              ev.timestamp != null ? Formatters.dateTime(ev.timestamp, locale) : (ev.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );

  Widget _audit(BuildContext context, String locale, String Function(int) person) => SectionCard<AuditLogEntry>(
          section: detail.auditLogs,
          maxItems: 10,
          itemBuilder: (context, log) => SectionRow(
            title: codeLabel(context.i18n, log.action),
            subtitle: [log.details, if (log.performedBy != null) person(log.performedBy!)].whereType<String>().join(' · '),
            trailing: Text(
              log.timestamp != null ? Formatters.dateTime(log.timestamp, locale) : (log.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
}

IconData _trendIcon(TrendDirection direction) => switch (direction) {
  TrendDirection.increasing => Icons.trending_up,
  TrendDirection.decreasing => Icons.trending_down,
  TrendDirection.stable => Icons.trending_flat,
  TrendDirection.unknown => Icons.remove,
};

BadgeTone _severityTone(DeviationSeverity severity) => switch (severity) {
  DeviationSeverity.critical => BadgeTone.critical,
  DeviationSeverity.warning => BadgeTone.warning,
  DeviationSeverity.onTrack => BadgeTone.success,
  DeviationSeverity.noData => BadgeTone.neutral,
};
