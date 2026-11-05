import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../../shared/presentation/formatting/context_locale.dart';
import '../../../../shared/presentation/formatting/formatters.dart';
import '../../../../shared/presentation/widgets/status_badge.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/severity_tone.dart';
import 'modern_card.dart';

class TrendRow extends StatelessWidget {
  const TrendRow({super.key, required this.trend, required this.data});
  final DeviationTrend trend;
  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final percent = trend.timeInRangePercent;
    final theme = Theme.of(context);
    final tone = timeInRangeToneFromSeverity(trend.severity);

    final iconColor = tone == BadgeTone.danger
        ? Colors.redAccent
        : (tone == BadgeTone.warning ? Colors.orange : Colors.green);

    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(trend.direction.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertVariable(l10n, trend.parameterName),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    data.deviceNames[trend.equipmentId],
                    l10n.deviationsSummary(trend.deviationCount, trend.criticalDeviationCount),
                  ].whereType<String>().join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          trend.severity == DeviationSeverity.noData
              ? StatusBadge(label: l10n.noData, tone: BadgeTone.neutral)
              : StatusBadge(
            label: percent == null
                ? '—'
                : l10n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
            tone: tone,
          ),
        ],
      ),
    );
  }
}