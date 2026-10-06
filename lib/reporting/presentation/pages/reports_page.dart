import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/reporting.dart';
import '../bloc/reports_bloc.dart';

String reportPeriodLabel(AppLocalizations l10n, ReportPeriod period) => switch (period) {
  ReportPeriod.last24Hours => l10n.period24h,
  ReportPeriod.last7Days => l10n.period7d,
  ReportPeriod.last31Days => l10n.period31d,
};

String reportTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'BATCH_TRACEABILITY' => l10n.reportBatchTraceability,
  'COMPLIANCE_PERIOD' => l10n.reportCompliance,
  'EQUIPMENT_LOG' => l10n.reportEquipmentLog,
  'INVENTORY' => l10n.reportInventory,
  'KPI_SUMMARY' => l10n.reportKpiSummary,
  _ => Formatters.humanize(type),
};

extension TrendDirectionPresentation on TrendDirection {
  IconData get icon => switch (this) {
    TrendDirection.increasing => Icons.trending_up,
    TrendDirection.decreasing => Icons.trending_down,
    TrendDirection.stable => Icons.trending_flat,
    TrendDirection.unknown => Icons.remove,
  };
}

/// As in Web, any time out of range is highlighted as a warning.
BadgeTone timeInRangeTone(double? percent) {
  if (percent == null) return BadgeTone.neutral;
  return percent < 100 ? BadgeTone.warning : BadgeTone.success;
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ReportsBloc>();
    void reload() => bloc.add(const ReportsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) => RemoteStateView<ReportsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.insights_outlined,
          emptyMessage: l10n.reportsEmpty,
          builder: (context, data) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(title: l10n.reportsTitle, subtitle: l10n.reportsSubtitle),
                const SizedBox(height: AppSpacing.md),
                FilterChipBar<ReportPeriod>(
                  options: ReportPeriod.values,
                  selected: state.period,
                  labelOf: (p) => reportPeriodLabel(l10n, p),
                  onSelected: (p) => bloc.add(ReportsPeriodChanged(p)),
                ),
                const SizedBox(height: AppSpacing.md),
                _MeasurementSummaryCard(data: data),
                const SizedBox(height: AppSpacing.md),
                SectionCard<DeviationTrend>(
                  title: l10n.deviationIndicators,
                  section: data.trends,
                  emptyMessage: l10n.noReadingsInPeriod,
                  itemBuilder: (context, t) => _TrendRow(trend: t, data: data),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard<AuditReport>(
                  title: l10n.reportHistory,
                  section: data.reports,
                  emptyMessage: l10n.reportHistoryEmpty,
                  itemBuilder: (context, r) => SectionRow(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: reportTypeLabel(l10n, r.reportType),
                    subtitle: [
                      if (r.dateRangeFrom != null || r.dateRangeTo != null)
                        '${Formatters.rawDate(r.dateRangeFrom, context.localeName)} – ${Formatters.rawDate(r.dateRangeTo, context.localeName)}',
                      if (r.generatedByName != null) r.generatedByName!,
                    ].join(' · '),
                    trailing: Text(
                      Formatters.dateTime(r.generatedAt, context.localeName),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.reportsGeneratedOnWeb, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasurementSummaryCard extends StatelessWidget {
  const _MeasurementSummaryCard({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final failure = data.kpiFailure;
    final summaries = data.kpi?.measurementSummaries ?? const <MeasurementSummary>[];
    return InfoCard(
      title: l10n.measurementSummary,
      child: failure != null
          ? Text(
              failureMessage(context, failure),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.critical),
            )
          : summaries.isEmpty
          ? Text(l10n.noReadingsInPeriod)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in summaries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SectionRow(
                      title: alertVariable(l10n, s.metric),
                      subtitle: [
                        data.environmentNames[s.environmentId],
                        data.deviceNames[s.deviceId],
                        l10n.readingsCount(s.readings),
                      ].whereType<String>().join(' · '),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${Formatters.number(s.average, locale)} ${s.unit ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            l10n.minMax(Formatters.number(s.minimum, locale), Formatters.number(s.maximum, locale)),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend, required this.data});

  final DeviationTrend trend;
  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final percent = trend.timeInRangePercent;
    return SectionRow(
      leading: Icon(trend.direction.icon, color: AppColors.primary),
      title: alertVariable(l10n, trend.parameterName),
      subtitle: [
        data.deviceNames[trend.equipmentId],
        l10n.deviationsSummary(trend.deviationCount, trend.criticalDeviationCount),
      ].whereType<String>().join(' · '),
      trailing: StatusBadge(
        label: percent == null ? '—' : l10n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
        tone: timeInRangeTone(percent),
      ),
    );
  }
}
