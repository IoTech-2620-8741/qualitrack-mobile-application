import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/reporting.dart';
import '../bloc/reports_bloc.dart';

String reportPeriodLabel(AppLocalizations i18n, ReportPeriod period) => switch (period) {
  ReportPeriod.last24Hours => i18n.period24h,
  ReportPeriod.last7Days => i18n.period7d,
  ReportPeriod.last31Days => i18n.period31d,
};

String reportTypeLabel(AppLocalizations i18n, String type) => switch (type) {
  'BATCH_TRACEABILITY' => i18n.reportBatchTraceability,
  'COMPLIANCE_PERIOD' => i18n.reportCompliance,
  'EQUIPMENT_LOG' => i18n.reportEquipmentLog,
  'INVENTORY' => i18n.reportInventory,
  'KPI_SUMMARY' => i18n.reportKpiSummary,
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

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<ReportsBloc>();
    void reload() => bloc.add(const ReportsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(i18n.reportsTitle)),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) => RemoteStateView<ReportsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.insights_outlined,
          emptyMessage: i18n.reportsEmpty,
          builder: (context, data) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(title: i18n.reportsTitle, subtitle: i18n.reportsSubtitle),
                const SizedBox(height: AppSpacing.md),
                FilterChipBar<ReportPeriod>(
                  options: ReportPeriod.values,
                  selected: state.period,
                  labelOf: (p) => reportPeriodLabel(i18n, p),
                  onSelected: (p) => bloc.add(ReportsPeriodChanged(p)),
                ),
                const SizedBox(height: AppSpacing.md),
                _MeasurementSummaryCard(data: data),
                const SizedBox(height: AppSpacing.md),
                SectionCard<DeviationTrend>(
                  title: i18n.deviationIndicators,
                  section: data.trends,
                  emptyMessage: i18n.noReadingsInPeriod,
                  itemBuilder: (context, t) => _TrendRow(trend: t, data: data),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard<AuditReport>(
                  title: i18n.reportHistory,
                  section: data.reports,
                  emptyMessage: i18n.reportHistoryEmpty,
                  itemBuilder: (context, r) => SectionRow(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: reportTypeLabel(i18n, r.reportType),
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
                Text(i18n.reportsGeneratedOnWeb, style: Theme.of(context).textTheme.bodySmall),
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
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final failure = data.kpiFailure;
    final summaries = data.kpi?.measurementSummaries ?? const <MeasurementSummary>[];
    return InfoCard(
      title: i18n.measurementSummary,
      child: failure != null
          ? Text(
              failureMessage(context, failure),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.critical),
            )
          : summaries.isEmpty
          ? Text(i18n.noReadingsInPeriod)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in summaries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SectionRow(
                      title: alertVariable(i18n, s.metric),
                      subtitle: [
                        data.environmentNames[s.environmentId],
                        data.deviceNames[s.deviceId],
                        i18n.readingsCount(s.readings),
                      ].whereType<String>().join(' · '),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${Formatters.number(s.average, locale)} ${s.unit ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            i18n.minMax(Formatters.number(s.minimum, locale), Formatters.number(s.maximum, locale)),
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
    final i18n = context.i18n;
    final locale = context.localeName;
    final percent = trend.timeInRangePercent;
    return SectionRow(
      leading: Icon(trend.direction.icon, color: AppColors.primary),
      title: alertVariable(i18n, trend.parameterName),
      subtitle: [
        data.deviceNames[trend.equipmentId],
        i18n.deviationsSummary(trend.deviationCount, trend.criticalDeviationCount),
      ].whereType<String>().join(' · '),
      trailing: StatusBadge(
        label: percent == null ? '—' : i18n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
        tone: timeInRangeTone(percent),
      ),
    );
  }
}
