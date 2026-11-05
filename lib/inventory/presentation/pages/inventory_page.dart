import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../domain/inventory.dart';
import '../bloc/inventory_bloc.dart';
import '../widgets/inventory_material_card.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  String _filterLabel(BuildContext context, InventoryFilter f) => switch (f) {
    InventoryFilter.all => context.l10n.filterAll,
    InventoryFilter.belowMinimum => context.l10n.belowMinimum,
    InventoryFilter.blockedStock => context.l10n.blockedStock,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<InventoryBloc>();
    void reload() => bloc.add(const InventoryRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryTitle)),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) => RemoteStateView<List<InventoryMaterial>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.science_outlined,
          emptyMessage: l10n.inventoryEmpty,
          builder: (context, all) {
            final items = state.visible;
            final low = state.belowMinimumCount;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: l10n.inventoryTitle, subtitle: l10n.materialsCount(all.length)),
                  if (low > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warningContainer,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.lowStockAlert(low),
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    hint: l10n.searchMaterials,
                    onChanged: (q) => bloc.add(InventoryQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilterChipBar<InventoryFilter>(
                    options: InventoryFilter.values,
                    selected: state.filter,
                    labelOf: (f) => _filterLabel(context, f),
                    onSelected: (f) => bloc.add(InventoryFilterChanged(f)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    SizedBox(height: 200, child: EmptyView(title: l10n.noResults))
                  else
                    for (final material in items) ...[
                      InventoryMaterialCard(material: material, environmentName:state.environmentNames[material.environmentId]),
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

