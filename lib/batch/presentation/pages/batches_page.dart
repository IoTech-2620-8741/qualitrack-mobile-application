import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../domain/batch.dart';
import '../bloc/batches_bloc.dart';
import '../widgets/batch_labels.dart';

class BatchesPage extends StatelessWidget {
  const BatchesPage({super.key});

  String _filterLabel(BuildContext context, BatchFilter f) {
    final l10n = context.l10n;
    return switch (f) {
      BatchFilter.all => l10n.filterAll,
      BatchFilter.pending => l10n.batchPending,
      BatchFilter.inProgress => l10n.batchInProgress,
      BatchFilter.released => l10n.batchReleased,
      BatchFilter.rejected => l10n.batchRejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<BatchesBloc>();
    void reload() => bloc.add(const BatchesRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchesTitle),
        actions: [
          IconButton(tooltip: l10n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<BatchesBloc, BatchesState>(
        builder: (context, state) => RemoteStateView<List<ProductionBatch>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.inventory_2_outlined,
          emptyMessage: l10n.batchesEmpty,
          builder: (context, _) {
            final summary = state.summary;
            final items = state.visible;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: l10n.batchesTitle, subtitle: l10n.batchesSubtitle),
                  const SizedBox(height: AppSpacing.md),
                  ResponsiveGrid(
                    minItemWidth: 100,
                    children: [
                      _Counter(label: l10n.total, value: summary.total, color: AppColors.navy),
                      _Counter(label: l10n.batchPending, value: summary.pending, color: AppColors.warning),
                      _Counter(label: l10n.batchInProgress, value: summary.inProgress, color: AppColors.info),
                      _Counter(label: l10n.batchReleased, value: summary.released, color: AppColors.success),
                      _Counter(label: l10n.batchRejected, value: summary.rejected, color: AppColors.critical),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    hint: l10n.searchBatches,
                    onChanged: (q) => bloc.add(BatchesQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilterChipBar<BatchFilter>(
                    options: BatchFilter.values,
                    selected: state.filter,
                    labelOf: (f) => _filterLabel(context, f),
                    onSelected: (f) => bloc.add(BatchesFilterChanged(f)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    SizedBox(height: 200, child: EmptyView(title: l10n.noResults))
                  else
                    for (final batch in items) ...[
                      BatchCard(
                        batch: batch,
                        onTap: () async {
                          await context.push('/batches/${batch.id}');
                          reload();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          child: Column(
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.overline.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$value', style: AppTypography.metric.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }
}

class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.onTap});

  final ProductionBatch batch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              Text(
                '${l10n.product}: ${batch.productName ?? '—'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: KeyValue(
                      label: l10n.quantity,
                      value: '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim(),
                    ),
                  ),
                  Expanded(
                    child: KeyValue(label: l10n.startDate, value: Formatters.rawDate(batch.startDate, locale)),
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
                      l10n.awaitingQaRelease,
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
