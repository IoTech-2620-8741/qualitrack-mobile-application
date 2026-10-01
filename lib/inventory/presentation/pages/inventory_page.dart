import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/inventory.dart';
import '../bloc/inventory_bloc.dart';
import '../widgets/inventory_labels.dart';

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
                    for (final m in items) ...[
                      _MaterialCard(material: m),
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

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});

  final InventoryMaterial material;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    String qty(double v) => '${Formatters.number(v, locale)} ${material.unit}'.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/inventory/${material.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(material.name, style: theme.textTheme.titleSmall),
                        Text(
                          material.code,
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: AppTypography.monospace),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: material.stockLabel(l10n), tone: material.stockTone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: KeyValue(label: l10n.usableStock, value: qty(material.usableStock))),
                  Expanded(child: KeyValue(label: l10n.physicalStock, value: qty(material.physicalStock))),
                  Expanded(child: KeyValue(label: l10n.minimumStock, value: qty(material.minimumStock))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
