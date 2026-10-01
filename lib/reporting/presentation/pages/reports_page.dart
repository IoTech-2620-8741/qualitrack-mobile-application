import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/reporting.dart';
import '../bloc/reports_bloc.dart';

extension KpiMetricStatusPresentation on KpiMetricStatus {
  BadgeTone get tone => switch (this) {
    KpiMetricStatus.onTrack => BadgeTone.success,
    KpiMetricStatus.atRisk => BadgeTone.warning,
    KpiMetricStatus.critical => BadgeTone.critical,
    KpiMetricStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    KpiMetricStatus.onTrack => l10n.kpiOnTrack,
    KpiMetricStatus.atRisk => l10n.kpiAtRisk,
    KpiMetricStatus.critical => l10n.severityCritical,
    KpiMetricStatus.unknown => l10n.unknown,
  };
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<ReportsBloc>().add(const ReportsRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: BlocBuilder<ReportsBloc, RemoteState<ReportsData>>(
        builder: (context, state) => RemoteStateView<ReportsData>(
          state: state,
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
                if (data.kpiFailure != null)
                  InfoCard(
                    title: l10n.kpiDashboard,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.critical, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            failureMessage(context, data.kpiFailure!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.critical,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (data.kpi == null)
                  InfoCard(title: l10n.kpiDashboard, child: Text(l10n.kpiEmpty))
                else
                  _KpiCard(kpi: data.kpi!),
                const SizedBox(height: AppSpacing.md),
                SectionCard<AuditReport>(
                  title: l10n.reportHistory,
                  section: data.reports,
                  emptyMessage: l10n.reportHistoryEmpty,
                  itemBuilder: (context, r) => SectionRow(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: Formatters.humanize(r.reportType),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final KpiDashboard kpi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    return InfoCard(
      title: l10n.kpiDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kpi.overallHealthScore != null) ...[
            Text(l10n.overallHealth.toUpperCase(), style: AppTypography.overline),
            Text(
              '${Formatters.number(kpi.overallHealthScore, locale, maxDecimals: 1)}%',
              style: AppTypography.metric,
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: l10n.overallHealth,
              value: '${kpi.overallHealthScore}',
              child: LinearProgressIndicator(
                value: (kpi.overallHealthScore! / 100).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.calculatedAt(Formatters.dateTime(kpi.timestamp, locale)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (kpi.metrics.isEmpty)
            Text(l10n.noInformation)
          else
            for (final m in kpi.metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SectionRow(
                  title: m.name,
                  subtitle: m.targetValue == null
                      ? null
                      : l10n.targetValue('${Formatters.number(m.targetValue, locale)} ${m.unit ?? ''}'.trim()),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${Formatters.number(m.value, locale)} ${m.unit ?? ''}'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      StatusBadge(label: m.status.label(l10n), tone: m.status.tone),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
