import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../../tracking/presentation/widgets/telemetry_labels.dart';
import '../bloc/equipment_list_bloc.dart';
import '../widgets/equipment_labels.dart';

class EquipmentListPage extends StatelessWidget {
  const EquipmentListPage({super.key});

  String _filterLabel(BuildContext context, EquipmentFilter filter) {
    final l10n = context.l10n;
    return switch (filter) {
      EquipmentFilter.all => l10n.filterAll,
      EquipmentFilter.attention => l10n.needsAttention,
      EquipmentFilter.operational => l10n.equipmentOperational,
      EquipmentFilter.maintenance => l10n.equipmentMaintenance,
      EquipmentFilter.outOfService => l10n.equipmentOutOfService,
      EquipmentFilter.inactive => l10n.inactive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<EquipmentListBloc>().add(const EquipmentListRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentTitle)),
      body: BlocBuilder<EquipmentListBloc, EquipmentListState>(
        builder: (context, state) => RemoteStateView<List<EquipmentOverview>>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.precision_manufacturing_outlined,
          emptyMessage: l10n.equipmentEmpty,
          builder: (context, all) {
            final items = state.visible;
            final attention = all.where((e) => e.needsAttention).length;
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(
                    title: l10n.equipmentTitle,
                    subtitle: l10n.equipmentSummary(all.length, attention),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    hint: l10n.searchEquipment,
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
                    SizedBox(height: 220, child: EmptyView(title: l10n.noResults))
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
    final l10n = context.l10n;
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
                          [e.type, e.model].whereType<String>().join(' · '),
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
                  StatusBadge(label: e.statusLabel(l10n), tone: e.status.tone),
                  TelemetryStatusBadge(status: item.telemetry),
                  if (item.telemetry != null) OnlineBadge(online: item.telemetry!.isOnline),
                  StatusBadge(
                    label: e.hasSensor ? l10n.sensorLinked : l10n.noSensor,
                    tone: e.hasSensor ? BadgeTone.info : BadgeTone.neutral,
                    icon: e.hasSensor ? Icons.sensors : Icons.sensors_off_outlined,
                  ),
                ],
              ),
              if (e.serialNumber != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('${l10n.serialNumber}: ${e.serialNumber}', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
