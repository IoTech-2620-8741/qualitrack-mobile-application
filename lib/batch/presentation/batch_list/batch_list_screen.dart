import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../domain/entities/production_batch.dart';
import '../widgets/batch_card.dart';
import 'bloc/bloc.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<BatchListBloc>();
    void reload() => bloc.add(const BatchListRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.batchesTitle),
        actions: [
          IconButton(tooltip: i18n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<BatchListBloc, BatchListState>(
        builder: (context, state) => RemoteStateView<List<ProductionBatch>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.inventory_2_outlined,
          emptyMessage: i18n.batchesEmpty,
          builder: (context, _) {
            final summary = state.summary;
            final items = state.visible;
            // The counters filter by status: choosing the active one shows every batch again.
            void choose(BatchFilter filter) => bloc.add(
              BatchListFilterChanged(state.filter == filter ? BatchFilter.all : filter),
            );
            Widget counter(BatchFilter filter, String label, int value, Color color) => _StatusCounter(
              key: Key('batch.counter.${filter.name}'),
              label: label,
              value: value,
              color: color,
              selected: state.filter == filter,
              onTap: () => choose(filter),
            );
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: i18n.batchesTitle, subtitle: i18n.batchesSubtitle),
                  const SizedBox(height: AppSpacing.md),
                  ResponsiveGrid(
                    minItemWidth: 100,
                    children: [
                      counter(BatchFilter.all, i18n.total, summary.total, AppColors.navy),
                      counter(BatchFilter.pending, i18n.batchPending, summary.pending, AppColors.warning),
                      counter(BatchFilter.inProgress, i18n.batchInProgress, summary.inProgress, AppColors.info),
                      counter(BatchFilter.released, i18n.batchReleased, summary.released, AppColors.success),
                      counter(BatchFilter.rejected, i18n.batchRejected, summary.rejected, AppColors.critical),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    // A new field, empty, after the filters are cleared.
                    key: ValueKey('batch.search.${state.clearCount}'),
                    hint: i18n.searchBatches,
                    onChanged: (q) => bloc.add(BatchListQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    _NoMatches(onClear: () => bloc.add(const BatchListFiltersCleared()))
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

/// Count of batches in a status; tapping it shows only those batches.
class _StatusCounter extends StatelessWidget {
  const _StatusCounter({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: selected ? color.withValues(alpha: 0.08) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
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
      ),
    );
  }
}

/// Shown when the status or the search hide every batch.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(i18n.noResults, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('batch.clearFilters'),
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text(i18n.clearFilters),
          ),
        ],
      ),
    );
  }
}
