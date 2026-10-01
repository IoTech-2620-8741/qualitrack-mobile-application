import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../reporting/domain/reporting.dart';
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
  const EquipmentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() =>
        context.read<EquipmentDetailBloc>().add(const EquipmentDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentDetail)),
      body: BlocBuilder<EquipmentDetailBloc, RemoteState<EquipmentDetail>>(
        builder: (context, state) => RemoteStateView<EquipmentDetail>(
          state: state,
          onRetry: reload,
          builder: (context, detail) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: _DetailBody(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final EquipmentDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final e = detail.equipment;
    final telemetry = detail.telemetry;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(
          title: e.name,
          subtitle: [e.type, e.model].whereType<String>().join(' · '),
        ),
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
              KeyValue(label: l10n.type, value: e.type ?? '—'),
              KeyValue(label: l10n.model, value: e.model ?? '—'),
              KeyValue(label: l10n.serialNumber, value: e.serialNumber ?? '—'),
              KeyValue(
                label: l10n.linkedSensor,
                value: e.hasSensor ? e.sensorExternalId! : l10n.noSensor,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.telemetryStatus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  TelemetryStatusBadge(status: telemetry),
                  if (telemetry != null) OnlineBadge(online: telemetry.isOnline),
                ],
              ),
              if (telemetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.lastHeartbeat}: ${telemetry.lastHeartbeat != null ? Formatters.dateTime(telemetry.lastHeartbeat, locale) : (telemetry.rawLastHeartbeat ?? '—')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.go('/telemetry?equipmentId=${e.id}'),
                icon: const Icon(Icons.monitor_heart_outlined),
                label: Text(l10n.viewTelemetry),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<BpmParameterConfig>(
          title: l10n.bpmLimits,
          section: detail.bpmConfigs,
          emptyMessage: l10n.bpmLimitsEmpty,
          itemBuilder: (context, c) => SectionRow(
            title: c.parameterName,
            trailing: Text(
              '${Formatters.number(c.minValue, locale)} – ${Formatters.number(c.maxValue, locale)} ${c.unit ?? ''}'
                  .trim(),
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
            trailing: Text(
              m.maintenanceDate != null ? Formatters.date(m.maintenanceDate, locale) : (m.rawDate ?? '—'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<DeviationTrend>(
          title: l10n.deviationTrends,
          section: detail.trends,
          itemBuilder: (context, t) => SectionRow(
            title: t.parameterName,
            subtitle: l10n.dataPointsCount(t.dataPoints.length),
            trailing: StatusBadge(
              label: _trendLabel(l10n, t.direction),
              tone: t.direction == TrendDirection.stable ? BadgeTone.success : BadgeTone.warning,
              icon: switch (t.direction) {
                TrendDirection.increasing => Icons.trending_up,
                TrendDirection.decreasing => Icons.trending_down,
                _ => Icons.trending_flat,
              },
            ),
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
            subtitle: log.details,
            trailing: Text(
              log.timestamp != null ? Formatters.dateTime(log.timestamp, locale) : (log.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  String _trendLabel(AppLocalizations l10n, TrendDirection direction) => switch (direction) {
    TrendDirection.increasing => l10n.trendIncreasing,
    TrendDirection.decreasing => l10n.trendDecreasing,
    TrendDirection.stable => l10n.trendStable,
    TrendDirection.unknown => l10n.unknown,
  };
}
