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
import '../widgets/inventory_filter_bar.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

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
                  InventoryFilterBar(
                    selectedFilter: state.filter,
                    onQueryChanged: (query) {
                      bloc.add(InventoryQueryChanged(query));
                    },
                    onFilterChanged: (filter) {
                      bloc.add(InventoryFilterChanged(filter));
                    },
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

