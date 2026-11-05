/// This file contains the Measurement Row widget.
///
/// It represents a single measurement summary item, displaying the metric name,
/// device, and its average/min-max values or event count (if it's a movement metric).
///

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../../shared/presentation/formatting/context_locale.dart';
import '../../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/kpi_entities.dart';
import 'modern_card.dart';

/// A widget that displays a single measurement summary.
class MeasurementRow extends StatelessWidget {
  const MeasurementRow({super.key, required this.summary, required this.data});

  /// The measurement summary entity to display.
  final MeasurementSummary summary;

  /// The reports data, used to get the device names.
  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);

    // Check if the metric is a movement event (which doesn't have averages)
    final isMovement = summary.metric.toLowerCase() == 'movement';

    return ModernCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Left Side: Metric Name and Device Name ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertVariable(l10n, summary.metric), // Translates metric codes
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

          // --- Right Side: Values (Average/Min-Max or Event Count) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMovement)
              // If it's a movement, show the event count
                Text(
                  summary.readings == 1
                      ? l10n.eventCount(summary.readings)
                      : l10n.eventCountPlural(summary.readings),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                )
              else
              // Otherwise, show the average value with its unit
                Text(
                  '${Formatters.number(summary.average, locale)} ${summary.unit ?? ''}'.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

              const SizedBox(height: 2),

              // Only show min/max if it's NOT a movement
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