import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/connection_badge.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/fab_menu.dart';
import '../../../common/presentation/widgets/filter_summary_card.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../bloc/equipment_list_bloc.dart';
import '../widgets/equipment_labels.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  String _filterLabel(BuildContext context, EquipmentFilter filter) {
    final i18n = context.i18n;
    return switch (filter) {
      EquipmentFilter.all => i18n.filterAll,
      EquipmentFilter.attention => i18n.needsAttention,
      EquipmentFilter.iotDevices => i18n.iotDevices,
      EquipmentFilter.operational => i18n.equipmentOperational,
      EquipmentFilter.maintenance => i18n.equipmentMaintenance,
      EquipmentFilter.outOfService => i18n.equipmentOutOfService,
      EquipmentFilter.inactive => i18n.inactive,
    };
  }

  IconData _filterIcon(EquipmentFilter filter) => switch (filter) {
    EquipmentFilter.all => Icons.list_alt,
    EquipmentFilter.attention => Icons.warning_amber_rounded,
    EquipmentFilter.iotDevices => Icons.sensors,
    EquipmentFilter.operational => Icons.check_circle_outline,
    EquipmentFilter.maintenance => Icons.build_outlined,
    EquipmentFilter.outOfService => Icons.block,
    EquipmentFilter.inactive => Icons.power_settings_new,
  };

  BadgeTone _filterTone(EquipmentFilter filter) => switch (filter) {
    EquipmentFilter.all => BadgeTone.neutral,
    EquipmentFilter.attention => BadgeTone.warning,
    EquipmentFilter.iotDevices => BadgeTone.info,
    EquipmentFilter.operational => BadgeTone.success,
    EquipmentFilter.maintenance => BadgeTone.warning,
    EquipmentFilter.outOfService => BadgeTone.critical,
    EquipmentFilter.inactive => BadgeTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<EquipmentListBloc>().add(const EquipmentListRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<EquipmentListBloc, EquipmentListState>(
          builder: (context, state) {
            final all = state.remote.data;
            return AppBarTitle(
              title: i18n.equipmentTitle,
              subtitle:
                  all == null ? null : i18n.equipmentSummary(all.length, all.where((e) => e.needsAttention).length),
            );
          },
        ),
      ),
      body: BlocBuilder<EquipmentListBloc, EquipmentListState>(
        builder:
            (context, state) => RemoteStateView<List<EquipmentOverview>>(
              state: state.remote,
              onRetry: reload,
              emptyIcon: Icons.precision_manufacturing_outlined,
              emptyMessage: i18n.equipmentEmpty,
              builder: (context, all) {
                final items = state.visible;
                // Same pattern as alerts and batches: compact summary card,
                // search, and the filter in a FAB menu with each count.
                return FabMenuHost<EquipmentFilter>(
                  icon: Icons.filter_list,
                  tooltip: i18n.filterEquipment,
                  selected: state.filter,
                  onSelected: (f) => context.read<EquipmentListBloc>().add(EquipmentFilterChanged(f)),
                  items: [
                    for (final f in EquipmentFilter.values)
                      FabMenuItem(
                        value: f,
                        label: _filterLabel(context, f),
                        icon: _filterIcon(f),
                        count: state.countFor(f),
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
                          filterLabel: _filterLabel(context, state.filter),
                          icon: _filterIcon(state.filter),
                          tone: _filterTone(state.filter),
                          count: items.length,
                          total: all.length,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchField(
                          hint: i18n.searchEquipment,
                          onChanged: (q) => context.read<EquipmentListBloc>().add(EquipmentQueryChanged(q)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (items.isEmpty)
                          SizedBox(height: 220, child: EmptyView(title: i18n.noResults))
                        else
                          for (final item in items) ...[
                            EquipmentCard(item: item),
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

class EquipmentCard extends StatelessWidget {
  const EquipmentCard({super.key, required this.item});

  final EquipmentOverview item;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final e = item.equipment;
    final attention = item.needsAttention;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/equipment/${e.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile list item: tonal leading icon, amber when the
                  // equipment needs attention.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: attention ? AppColors.warningContainer : AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      e.deviceType != null ? Icons.sensors : Icons.precision_manufacturing_outlined,
                      size: 22,
                      color: attention ? AppColors.warning : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [if (e.deviceType == null) e.type, item.environmentName].whereType<String>().join(' · '),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: 40 + AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(label: e.statusLabel(i18n), tone: e.status.tone),
                    if (e.deviceType != null) ...[
                      StatusBadge(label: e.deviceType!.label(i18n), tone: BadgeTone.info, icon: Icons.sensors),
                      if (e.environmentId != null) ConnectionBadge(connected: item.connection?.reachable),
                    ],
                  ],
                ),
              ),
              if (e.serialNumber != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 40 + AppSpacing.md),
                  child: Text('${i18n.serialNumber}: ${e.serialNumber}', style: theme.textTheme.bodySmall),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
