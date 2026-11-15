import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/widgets/minute_ticker.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/fab_menu.dart';
import '../../../common/presentation/widgets/filter_summary_card.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/batch_summary.dart';
import '../../domain/entities/production_batch.dart';
import '../widgets/batch_card.dart';
import 'bloc/bloc.dart';

/// Production batches of the laboratory.
///
/// Same pattern as the alerts: a compact summary card for the status in use,
/// a search bar and the matching batches. The status is chosen from a FAB
/// menu at the bottom-right corner, where each option shows its count.
class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<BatchListBloc>();
    void reload() => bloc.add(const BatchListRequested(refresh: true));
    return Scaffold(
      // How current the list is, once loaded ("Updated 2 min ago").
      appBar: AppBar(
        title: BlocBuilder<BatchListBloc, BatchListState>(
          buildWhen: (a, b) => a.remote.loadedAt != b.remote.loadedAt,
          builder: (context, state) => MinuteTicker(
            builder: (context) {
              final at = state.remote.loadedAt;
              return AppBarTitle(
                title: i18n.batchesTitle,
                subtitle: at == null ? i18n.batchesSubtitle : updatedText(context, at),
              );
            },
          ),
        ),
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
            final style = _FilterStyle.of(state.filter);
            return FabMenuHost<BatchFilter>(
              icon: Icons.filter_list,
              tooltip: i18n.filterBatches,
              selected: state.filter,
              onSelected: (f) => bloc.add(BatchListFilterChanged(f)),
              items: [
                for (final f in BatchFilter.values)
                  FabMenuItem(
                    value: f,
                    label: _FilterStyle.of(f).label(i18n),
                    icon: _FilterStyle.of(f).icon,
                    count: _count(f, summary),
                  ),
              ],
              child: RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    FabMenuHost.bottomClearance,
                  ),
                  children: [
                    FilterSummaryCard(
                      key: const Key('batch.summary'),
                      filterLabel: style.label(i18n),
                      icon: style.icon,
                      tone: style.tone,
                      count: items.length,
                      total: summary.total,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

int _count(BatchFilter filter, BatchSummary s) => switch (filter) {
  BatchFilter.all => s.total,
  BatchFilter.pending => s.pending,
  BatchFilter.inProgress => s.inProgress,
  BatchFilter.released => s.released,
  BatchFilter.rejected => s.rejected,
};

/// Label, icon and tone of each status filter, shared by the menu and the card.
final class _FilterStyle {
  const _FilterStyle(this.label, this.icon, this.tone);

  final String Function(AppLocalizations i18n) label;
  final IconData icon;
  final BadgeTone tone;

  static _FilterStyle of(BatchFilter filter) => switch (filter) {
    BatchFilter.all => _FilterStyle((i) => i.filterAll, Icons.list_alt, BadgeTone.neutral),
    BatchFilter.pending => _FilterStyle((i) => i.batchPending, Icons.hourglass_empty, BadgeTone.warning),
    BatchFilter.inProgress => _FilterStyle((i) => i.batchInProgress, Icons.autorenew, BadgeTone.info),
    BatchFilter.released => _FilterStyle((i) => i.batchReleased, Icons.verified_outlined, BadgeTone.success),
    BatchFilter.rejected => _FilterStyle((i) => i.batchRejected, Icons.block, BadgeTone.critical),
  };
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
