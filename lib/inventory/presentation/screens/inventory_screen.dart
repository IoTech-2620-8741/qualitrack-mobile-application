import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../domain/entities/inventory_material.dart';
import '../bloc/inventory_bloc.dart';
import '../widgets/inventory_material_card.dart';
import '../widgets/inventory_filter_bar.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<InventoryBloc>();
    void reload() => bloc.add(const InventoryRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(i18n.inventoryTitle)),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) => RemoteStateView<List<InventoryMaterial>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.science_outlined,
          emptyMessage: i18n.inventoryEmpty,
          builder: (context, all) {
            final items = state.visible;
            final low = state.belowMinimumCount;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(title: i18n.inventoryTitle, subtitle: i18n.materialsCount(all.length)),
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
                                i18n.lowStockAlert(low),
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
                    SizedBox(height: 200, child: EmptyView(title: i18n.noResults))
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

