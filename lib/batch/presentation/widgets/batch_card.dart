import 'package:flutter/material.dart';

import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/production_batch.dart';
import 'batch_labels.dart';

/// A batch as a mobile list item: status icon, batch number and status on
/// the first line, the product below, then quantity · start date. The status
/// badge says whether it awaits the QA decision, so no extra line repeats it.
class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.onTap});

  final ProductionBatch batch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final text = Theme.of(context).textTheme;
    final tone = batch.status.tone;
    final quantity = '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
                child: Icon(Icons.inventory_2_outlined, size: 22, color: tone.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            batch.batchNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTypography.monospace,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        BatchStatusBadge(status: batch.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      batch.productName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Quantity and start date as icon + value; their names
                    // are read by screen readers only.
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _Meta(icon: Icons.scale_outlined, label: i18n.quantity, value: quantity),
                        _Meta(
                          icon: Icons.event_outlined,
                          label: i18n.startDate,
                          value: Formatters.rawDate(batch.startDate, locale),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.sm),
                  child: Icon(Icons.chevron_right, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon + value; the label is only for screen readers.
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
