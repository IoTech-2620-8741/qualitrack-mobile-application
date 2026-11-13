/// This file contains the Trend Row widget.
///
/// It represents a single deviation trend item, displaying the direction icon,
/// parameter name, equipment name, deviation counts, and time-in-range badge.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/deviation_entities.dart';
import '../../domain/entities/reporting_enums.dart';
import '../widgets/severity_tone.dart';
import 'modern_card.dart';

/// A widget that displays a single deviation trend.
class TrendRow extends StatelessWidget {
  const TrendRow({super.key, required this.trend, required this.data});

  /// The deviation trend entity to display.
  final DeviationTrend trend;

  /// The reports data, used to get equipment names.
  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final percent = trend.timeInRangePercent;
    final theme = Theme.of(context);

    // Get the visual tone (color) based on the severity
    final tone = timeInRangeToneFromSeverity(trend.severity);

    // The arrow only says the direction (neutral): whether that is good or
    // bad is the badge, in the colour of its severity.
    const iconColor = AppColors.textMuted;

    return ModernCard(
      child: Row(
        children: [
          // 1. Circular container with the direction icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.neutralContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(trend.direction.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),

          // 2. Main content (Parameter Name and Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertVariable(i18n, trend.parameterName),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    data.deviceNames[trend.equipmentId],
                    i18n.deviationsSummary(trend.deviationCount, trend.criticalDeviationCount),
                  ].whereType<String>().join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // 3. Status Badge (Time in range percentage or "No Data")
          trend.severity == DeviationSeverity.noData
              ? StatusBadge(label: i18n.noData, tone: BadgeTone.neutral)
              : StatusBadge(
            label: percent == null
                ? '—'
                : i18n.timeInRange('${Formatters.number(percent, locale, maxDecimals: 1)}%'),
            tone: tone,
          ),
        ],
      ),
    );
  }
}