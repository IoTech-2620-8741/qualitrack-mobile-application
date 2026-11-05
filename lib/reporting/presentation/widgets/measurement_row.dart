import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../../shared/presentation/formatting/context_locale.dart';
import '../../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../application/reporting_facade_service.dart';
import 'modern_card.dart';

class MeasurementRow extends StatelessWidget {
  const MeasurementRow({super.key, required this.summary, required this.data});
  final MeasurementSummary summary;
  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final isMovement = summary.metric.toLowerCase() == 'movement';

    return ModernCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertVariable(l10n, summary.metric),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  data.deviceNames[summary.deviceId] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              isMovement
                  ? Text(
                summary.readings == 1
                    ? l10n.eventCount(summary.readings)
                    : l10n.eventCountPlural(summary.readings),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              )
                  : Text(
                '${Formatters.number(summary.average, locale)} ${summary.unit ?? ''}'.trim(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              if (!isMovement)
                Text(
                  l10n.minMax(
                    Formatters.number(summary.minimum, locale),
                    Formatters.number(summary.maximum, locale),
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}