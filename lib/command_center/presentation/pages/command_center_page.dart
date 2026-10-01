import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../iam/domain/user_session.dart';
import '../../../iam/presentation/widgets/role_labels.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../application/get_command_center_summary.dart';
import '../bloc/command_center_bloc.dart';

class CommandCenterPage extends StatelessWidget {
  const CommandCenterPage({super.key, required this.session});

  final UserSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<CommandCenterBloc>().add(const CommandCenterRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          IconButton(tooltip: l10n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: l10n.profile,
            onPressed: () => context.push('/profile'),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                session.username.isEmpty ? '?' : session.username[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
        builder: (context, state) => RemoteStateView<CommandCenterSummary>(
          state: state,
          onRetry: reload,
          builder: (context, summary) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(title: l10n.commandCenterTitle, subtitle: l10n.commandCenterSubtitle),
                const SizedBox(height: AppSpacing.md),
                _Hero(session: session, summary: summary),
                SectionHeader(title: l10n.keyOperationalMetrics),
                _Metrics(summary: summary),
                SectionHeader(title: l10n.liveTelemetry, subtitle: l10n.liveTelemetryHint),
                _TelemetryCard(summary: summary),
                SectionHeader(title: l10n.riskOverview, subtitle: l10n.riskOverviewHint),
                _RiskOverview(summary: summary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.session, required this.summary});

  final UserSession session;
  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final lab = summary.laboratory.value;
    final kpi = summary.kpi.value;
    final alerts = summary.alerts.value;
    final sub = summary.subscription;
    const light = TextStyle(color: Colors.white70, fontSize: 12);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.xlAll,
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.welcomeUser(session.username), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [session.primaryRole?.label(l10n), lab?.name ?? l10n.laboratoryNumber(session.laboratoryId?.toString() ?? '—')]
                .whereType<String>()
                .join(' · '),
            style: light,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (alerts != null)
                StatusBadge(
                  label: alerts.critical > 0
                      ? l10n.criticalAlertsCount(alerts.critical)
                      : l10n.noCriticalAlerts,
                  tone: alerts.critical > 0 ? BadgeTone.critical : BadgeTone.success,
                ),
              if (sub.isOk && sub.value != null)
                StatusBadge(
                  label: '${l10n.plan}: ${sub.value!.planCode} · ${Formatters.humanize(sub.value!.status)}',
                  tone: BadgeTone.brand,
                ),
              if (sub.isOk && sub.value == null)
                StatusBadge(label: l10n.noActiveSubscription, tone: BadgeTone.warning),
            ],
          ),
          if (kpi != null && kpi.overallHealthScore != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: AppRadius.lgAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.overallHealth.toUpperCase(), style: light),
                  Text(
                    '${Formatters.number(kpi.overallHealthScore, locale, maxDecimals: 1)}%',
                    style: AppTypography.metric.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: (kpi.overallHealthScore! / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.calculatedAt(Formatters.dateTime(kpi.timestamp, locale)), style: light),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary});

  final CommandCenterSummary summary;

  String _value<T>(Part<T> part, String Function(T value) read) =>
      part.isOk && part.value != null ? read(part.value as T) : '—';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eq = summary.equipment;
    final batches = summary.batches;
    final alerts = summary.alerts;
    final materials = summary.materials;
    final lowStock = materials.value?.where((m) => m.isBelowMinimum).length;
    return ResponsiveGrid(
      children: [
        MetricTile(
          label: l10n.equipmentTitle,
          value: _value(eq, (v) => '${v.total}'),
          caption: eq.isOk ? l10n.operationalCount(eq.value!.operational) : _err(context, eq.failure),
          icon: Icons.precision_manufacturing_outlined,
          color: AppColors.info,
          onTap: () => context.push('/equipment'),
        ),
        MetricTile(
          label: l10n.batchesTitle,
          value: _value(batches, (v) => '${v.total}'),
          caption: batches.isOk
              ? l10n.pendingInProgress(batches.value!.pending, batches.value!.inProgress)
              : _err(context, batches.failure),
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
          onTap: () => context.go('/batches'),
        ),
        MetricTile(
          label: l10n.openAlerts,
          value: _value(alerts, (v) => '${v.open}'),
          caption: alerts.isOk ? l10n.criticalCount(alerts.value!.critical) : _err(context, alerts.failure),
          icon: Icons.notifications_active_outlined,
          color: AppColors.critical,
          onTap: () => context.go('/alerts'),
        ),
        MetricTile(
          label: l10n.rawMaterials,
          value: _value(materials, (v) => '${v.length}'),
          caption: materials.isOk ? l10n.lowStockCount(lowStock ?? 0) : _err(context, materials.failure),
          icon: Icons.science_outlined,
          color: AppColors.warning,
          onTap: () => context.push('/inventory'),
        ),
      ],
    );
  }

  String _err(BuildContext context, Failure? failure) =>
      failure == null ? '' : failureMessage(context, failure).split('\n').first;
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eq = summary.equipment;
    if (!eq.isOk) {
      return InfoCard(child: Text(failureMessage(context, eq.failure!)));
    }
    final snapshot = eq.value!;
    final attention = snapshot.telemetryAttention;
    final tone = snapshot.total == 0
        ? BadgeTone.neutral
        : (attention > 0 ? BadgeTone.warning : (snapshot.online > 0 ? BadgeTone.success : BadgeTone.neutral));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/telemetry'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi_tethering, color: tone.foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      snapshot.total == 0
                          ? l10n.equipmentEmpty
                          : l10n.onlineOfTotal(snapshot.online, snapshot.total),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: l10n.onlineDevices, value: snapshot.online)),
                  Expanded(child: _MiniStat(label: l10n.telemetryAttention, value: attention, alert: attention > 0)),
                  Expanded(child: _MiniStat(label: l10n.withoutStatus, value: snapshot.total - snapshot.statuses.length)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.alert = false});

  final String label;
  final int value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.metric.copyWith(
              fontSize: 22,
              color: alert ? AppColors.critical : AppColors.textPrimary,
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RiskOverview extends StatelessWidget {
  const _RiskOverview({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <Widget>[];
    final materials = summary.materials.value;
    if (materials != null) {
      rows.add(_RiskRow(
        label: l10n.lowStock,
        count: materials.where((m) => m.isBelowMinimum).length,
        total: materials.length,
        color: AppColors.warning,
        caption: l10n.itemsCount(materials.where((m) => m.isBelowMinimum).length),
      ));
    }
    final eq = summary.equipment.value;
    if (eq != null) {
      rows.add(_RiskRow(
        label: l10n.equipmentMaintenance,
        count: eq.maintenance,
        total: eq.total,
        color: AppColors.info,
        caption: l10n.itemsCount(eq.maintenance),
      ));
    }
    final alerts = summary.alerts.value;
    if (alerts != null) {
      rows.add(_RiskRow(
        label: l10n.criticalOpen,
        count: alerts.critical,
        total: alerts.open,
        color: AppColors.critical,
        caption: l10n.criticalAlertsCount(alerts.critical),
      ));
    }
    final kpi = summary.kpi.value;
    if (kpi != null) {
      rows.add(_RiskRow(
        label: l10n.kpisAtRisk,
        count: kpi.atRiskCount,
        total: kpi.metrics.length,
        color: AppColors.critical,
        caption: l10n.itemsCount(kpi.atRiskCount),
      ));
    }
    if (eq != null) {
      rows.add(_RiskRow(
        label: l10n.telemetryAttention,
        count: eq.telemetryAttention,
        total: eq.total,
        color: AppColors.primary,
        caption: l10n.itemsCount(eq.telemetryAttention),
      ));
    }
    return InfoCard(
      child: rows.isEmpty
          ? Text(l10n.noInformation)
          : Column(children: [for (final r in rows) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: r)]),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.caption,
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$label: $caption',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
              Text(caption, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: ratio,
            color: color,
            backgroundColor: AppColors.neutralContainer,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
