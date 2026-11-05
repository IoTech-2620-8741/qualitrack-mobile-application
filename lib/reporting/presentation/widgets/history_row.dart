import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/presentation/formatting/context_locale.dart';
import '../../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../widgets/report_labels.dart';
import 'modern_card.dart';

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.report});
  final AuditReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);

    final from = report.dateRangeFrom;
    final to = report.dateRangeTo;
    final String? rangeText;
    if (from != null && to != null) {
      rangeText = '${Formatters.rawDate(from, locale)} – ${Formatters.rawDate(to, locale)}';
    } else if (from != null) {
      rangeText = Formatters.rawDate(from, locale);
    } else if (to != null) {
      rangeText = '– ${Formatters.rawDate(to, locale)}';
    } else {
      rangeText = null;
    }

    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportTypeLabel(l10n, report.reportType),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (rangeText != null) rangeText,
                    if (report.generatedByName != null) report.generatedByName!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            Formatters.dateTime(report.generatedAt, locale),
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}