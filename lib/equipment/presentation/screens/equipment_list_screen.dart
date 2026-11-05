import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/connection_badge.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<EquipmentListBloc>().add(const EquipmentListRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(i18n.equipmentTitle)),
      body: BlocBuilder<EquipmentListBloc, EquipmentListState>(
        builder: (context, state) => RemoteStateView<List<EquipmentOverview>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.precision_manufacturing_outlined,
          emptyMessage: i18n.equipmentEmpty,
          builder: (context, all) {
            final items = state.visible;
            final attention = all.where((e) => e.needsAttention).length;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(
                    title: i18n.equipmentTitle,
                    subtitle: i18n.equipmentSummary(all.length, attention),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    hint: i18n.searchEquipment,
                    onChanged: (q) => context.read<EquipmentListBloc>().add(EquipmentQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilterChipBar<EquipmentFilter>(
                    options: EquipmentFilter.values,
                    selected: state.filter,
                    labelOf: (f) => _filterLabel(context, f),
                    onSelected: (f) =>
                        context.read<EquipmentListBloc>().add(EquipmentFilterChanged(f)),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.needsAttention ? AppColors.warning : AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/equipment/${e.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.precision_manufacturing_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: theme.textTheme.titleSmall),
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
              Wrap(
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
              if (e.serialNumber != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('${i18n.serialNumber}: ${e.serialNumber}', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
