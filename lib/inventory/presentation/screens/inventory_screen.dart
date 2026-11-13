import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/fab_menu.dart';
import '../../../common/presentation/widgets/filter_summary_card.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/inventory_material.dart';
import '../bloc/inventory_bloc.dart';
import '../widgets/inventory_material_card.dart';

/// Raw materials inventory.
///
/// Same pattern as alerts, batches and equipment: a compact summary card for
/// the filter in use, a search bar and the matching materials. The stock
/// filter is chosen from a FAB menu at the bottom-right corner, where each
/// option shows how many materials it has.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<InventoryBloc>();
    void reload() => bloc.add(const InventoryRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, state) {
            final all = state.remote.data;
            return AppBarTitle(
              title: i18n.inventoryTitle,
              subtitle: all == null ? null : i18n.materialsCount(all.length),
            );
          },
        ),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) => RemoteStateView<List<InventoryMaterial>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.science_outlined,
          emptyMessage: i18n.inventoryEmpty,
          builder: (context, all) {
            final items = state.visible;
            final style = _FilterStyle.of(state.filter);
            int count(InventoryFilter f) => switch (f) {
              InventoryFilter.all => all.length,
              InventoryFilter.belowMinimum => state.belowMinimumCount,
              InventoryFilter.blockedStock => all.where((m) => m.hasBlockedStock).length,
            };
            return FabMenuHost<InventoryFilter>(
              icon: Icons.filter_list,
              tooltip: i18n.filterMaterials,
              selected: state.filter,
              onSelected: (f) => bloc.add(InventoryFilterChanged(f)),
              items: [
                for (final f in InventoryFilter.values)
                  FabMenuItem(
                    value: f,
                    label: _FilterStyle.of(f).label(i18n),
                    icon: _FilterStyle.of(f).icon,
                    count: count(f),
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
                      filterLabel: style.label(i18n),
                      icon: style.icon,
                      tone: style.tone,
                      count: items.length,
                      total: all.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SearchField(hint: i18n.searchMaterials, onChanged: (q) => bloc.add(InventoryQueryChanged(q))),
                    const SizedBox(height: AppSpacing.md),
                    if (items.isEmpty)
                      SizedBox(height: 200, child: EmptyView(title: i18n.noResults))
                    else
                      for (final material in items) ...[
                        InventoryMaterialCard(
                          material: material,
                          environmentName: state.environmentNames[material.environmentId],
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

/// Label, icon and tone of each stock filter, shared by the menu and the card.
final class _FilterStyle {
  const _FilterStyle(this.label, this.icon, this.tone);

  final String Function(AppLocalizations i18n) label;
  final IconData icon;
  final BadgeTone tone;

  static _FilterStyle of(InventoryFilter filter) => switch (filter) {
    InventoryFilter.all => _FilterStyle((i) => i.filterAll, Icons.list_alt, BadgeTone.neutral),
    InventoryFilter.belowMinimum => _FilterStyle((i) => i.belowMinimum, Icons.trending_down, BadgeTone.warning),
    InventoryFilter.blockedStock => _FilterStyle((i) => i.blockedStock, Icons.lock_outline, BadgeTone.warning),
  };
}
