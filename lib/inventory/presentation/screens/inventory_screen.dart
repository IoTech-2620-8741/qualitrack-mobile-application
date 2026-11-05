import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/inventory_material.dart';
import '../bloc/inventory_bloc.dart';
import '../widgets/inventory_labels.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  String _filterLabel(BuildContext context, InventoryFilter f) => switch (f) {
    InventoryFilter.all => context.i18n.filterAll,
    InventoryFilter.belowMinimum => context.i18n.belowMinimum,
    InventoryFilter.blockedStock => context.i18n.blockedStock,
  };

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
                  SearchField(
                    hint: i18n.searchMaterials,
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
                    SizedBox(height: 200, child: EmptyView(title: i18n.noResults))
                  else
                    for (final m in items) ...[
                      _MaterialCard(material: m, environmentName: state.environmentNames[m.environmentId]),
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
  const _MaterialCard({required this.material, this.environmentName});

  final InventoryMaterial material;
  final String? environmentName;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    String qty(double v) => '${Formatters.number(v, locale)} ${material.unit}'.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/inventory/${material.id}?environmentId=${material.environmentId}'),
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
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: material.code,
                                style: const TextStyle(fontFamily: AppTypography.monospace),
                              ),
                              if (environmentName != null) TextSpan(text: ' · $environmentName'),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: material.stockLabel(i18n), tone: material.stockTone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: KeyValue(label: i18n.usableStock, value: qty(material.usableStock))),
                  Expanded(child: KeyValue(label: i18n.physicalStock, value: qty(material.physicalStock))),
                  Expanded(child: KeyValue(label: i18n.minimumStock, value: qty(material.minimumStock))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
