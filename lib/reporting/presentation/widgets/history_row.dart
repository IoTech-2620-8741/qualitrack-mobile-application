/// This file contains the History Row widget.
///
/// It represents a single audit report item in the list, displaying the
/// report type, date range, generator name, and generation date.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../domain/entities/audit_entities.dart';
import '../widgets/report_labels.dart';
import 'modern_card.dart';

/// A widget that displays a single audit report.
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.report});

  /// The audit report entity to display.
  final AuditReport report;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);

    // --- Format the date range ---
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
          // 1. Circular icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),

          // 2. Main content (Report Type and Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportTypeLabel(i18n, report.reportType),
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

          // 3. Generation Date (Right aligned)
          Text(
            Formatters.dateTime(report.generatedAt, locale),
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}