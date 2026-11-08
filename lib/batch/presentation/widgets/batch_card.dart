import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../domain/entities/production_batch.dart';
import 'batch_labels.dart';

/// Summary card of a batch in the batch list.
class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.onTap});

  final ProductionBatch batch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final awaiting = batch.isAwaitingReview;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: awaiting ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: theme.textTheme.titleSmall?.copyWith(fontFamily: AppTypography.monospace),
                    ),
                  ),
                  BatchStatusBadge(status: batch.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(batch.productName ?? '—', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: KeyValue(
                      label: i18n.quantity,
                      value: '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim(),
                    ),
                  ),
                  Expanded(
                    child: KeyValue(label: i18n.startDate, value: Formatters.rawDate(batch.startDate, locale)),
                  ),
                ],
              ),
              if (awaiting) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.pending_actions_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      i18n.awaitingQaRelease,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
