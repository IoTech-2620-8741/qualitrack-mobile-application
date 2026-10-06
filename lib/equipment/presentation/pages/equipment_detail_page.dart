import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../reporting/presentation/pages/reports_page.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../../tracking/presentation/widgets/telemetry_labels.dart';
import '../../domain/equipment.dart';
import '../bloc/equipment_detail_bloc.dart';
import '../widgets/equipment_labels.dart';

class EquipmentDetailPage extends StatelessWidget {
  const EquipmentDetailPage({super.key, required this.currentUserId});

  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<EquipmentDetailBloc>().add(const EquipmentDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentDetail)),
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
    final l10n = context.l10n;
    final locale = context.localeName;
    final e = detail.equipment;
    final connection = detail.connection;
    String person(int userId) => userId == currentUserId ? l10n.you : (detail.people[userId] ?? l10n.userNumber(userId));
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(title: e.name, subtitle: [e.type, e.model].whereType<String>().join(' · ')),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.generalInformation,
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              KeyValue(
                label: l10n.status,
                value: e.statusLabel(l10n),
                valueWidget: StatusBadge(label: e.statusLabel(l10n), tone: e.status.tone),
              ),
              KeyValue(label: l10n.environment, value: detail.environmentName ?? l10n.notLocated),
              KeyValue(label: l10n.type, value: e.type ?? '—'),
              KeyValue(label: l10n.model, value: e.model ?? '—'),
              KeyValue(label: l10n.serialNumber, value: e.serialNumber ?? '—'),
              if (e.deviceType != null) KeyValue(label: l10n.iotRole, value: e.deviceType!.label(l10n)),
              if (e.sensorExternalId != null) KeyValue(label: l10n.deviceIdentifier, value: e.sensorExternalId!),
              if (e.firmwareVersion != null) KeyValue(label: l10n.firmware, value: e.firmwareVersion!),
            ],
          ),
        ),
        if (e.isIotDevice) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: l10n.connectionStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: ConnectionBadge(connection: connection)),
                if (connection != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.lastCommunication}: ${connection.lastCommunicationAt == null ? l10n.neverCommunicated : Formatters.dateTime(connection.lastCommunicationAt, locale)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (e.environmentId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/telemetry?deviceId=${e.id}'),
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: Text(l10n.viewTelemetry),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard<DeviationTrend>(
            title: l10n.deviationIndicators7d,
            section: detail.trends,
            emptyMessage: l10n.noReadingsInPeriod,
            itemBuilder: (context, t) {
              final percent = t.timeInRangePercent;
              return SectionRow(
                leading: Icon(t.direction.icon),
                title: alertVariable(l10n, t.parameterName),
                subtitle: l10n.deviationsSummary(t.deviationCount, t.criticalDeviationCount),
                trailing: StatusBadge(
                  label: percent == null ? '—' : l10n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
                  tone: timeInRangeTone(percent),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionCard<BpmParameterConfig>(
          title: l10n.bpmLimits,
          section: detail.bpmConfigs,
          emptyMessage: l10n.bpmLimitsEmpty,
          itemBuilder: (context, c) => SectionRow(
            title: c.parameterName,
            trailing: Text(
              '${Formatters.number(c.minValue, locale)} – ${Formatters.number(c.maxValue, locale)} ${c.unit ?? ''}'.trim(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<MaintenanceRecord>(
          title: l10n.maintenanceHistory,
          section: detail.maintenance,
          emptyMessage: l10n.maintenanceEmpty,
          itemBuilder: (context, m) => SectionRow(
            title: Formatters.humanize(m.type),
            subtitle: [m.description, m.technicianName].whereType<String>().join(' · '),
            trailing: Text(m.maintenanceDate != null ? Formatters.date(m.maintenanceDate, locale) : (m.rawDate ?? '—')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<ComplianceEvent>(
          title: l10n.complianceEvents,
          section: detail.events,
          maxItems: 10,
          itemBuilder: (context, ev) => SectionRow(
            title: Formatters.humanize(ev.eventType),
            subtitle: ev.description,
            trailing: Text(
              ev.timestamp != null ? Formatters.dateTime(ev.timestamp, locale) : (ev.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<AuditLogEntry>(
          title: l10n.auditLog,
          section: detail.auditLogs,
          maxItems: 10,
          itemBuilder: (context, log) => SectionRow(
            title: Formatters.humanize(log.action),
            subtitle: [log.details, if (log.performedBy != null) person(log.performedBy!)].whereType<String>().join(' · '),
            trailing: Text(
              log.timestamp != null ? Formatters.dateTime(log.timestamp, locale) : (log.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
