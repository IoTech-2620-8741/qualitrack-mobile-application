import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../common/presentation/widgets/secondary_tabs.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_receipt.dart';
import '../../domain/entities/material_usage.dart';
import '../bloc/material_detail_bloc.dart';
import '../widgets/inventory_labels.dart';
import '../widgets/inventory_receipt_item.dart';
import '../widgets/inventory_movement_item.dart';
import '../widgets/material_usage_item.dart';
import '../widgets/material_stock_summary.dart';

class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<MaterialDetailBloc>().add(const MaterialDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<MaterialDetailBloc, RemoteState<MaterialDetail>>(
          builder: (context, state) {
            final m = state.data?.material;
            return AppBarTitle(title: m?.name ?? i18n.materialDetail, subtitle: m?.code);
          },
        ),
        actions: [
          BlocBuilder<MaterialDetailBloc, RemoteState<MaterialDetail>>(
            builder: (context, state) {
              final m = state.data?.material;
              if (m == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Center(child: StatusBadge(label: m.stockLabel(i18n), tone: m.stockTone)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MaterialDetailBloc, RemoteState<MaterialDetail>>(
        builder: (context, state) => RemoteStateView<MaterialDetail>(
          state: state,
          onRetry: reload,
          builder: (context, detail) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: _Body(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final MaterialDetail detail;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final m = detail.material;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        
        MaterialStockSummary(
          material: m,
          environmentName: detail.environmentName,
        ),

        const SizedBox(height: AppSpacing.lg),
        // Lots, movements and usages are related views of the same material:
        // secondary tabs instead of three stacked cards.
        SecondaryTabs(
          tabs: [
            SecondaryTab(
              label: i18n.materialLots,
              builder: (context) => SectionCard<InventoryReceipt>(
                section: detail.receipts,
                emptyMessage: i18n.receiptsEmpty,
                itemBuilder: (context, receipt) => InventoryReceiptItem(receipt: receipt, defaultUnit: m.unit),
              ),
            ),
            SecondaryTab(
              label: i18n.tabMovements,
              builder: (context) => SectionCard<InventoryMovement>(
                section: detail.movements,
                emptyMessage: i18n.movementsEmpty,
                itemBuilder: (context, movement) => InventoryMovementItem(movement: movement, defaultUnit: m.unit),
              ),
            ),
            SecondaryTab(
              label: i18n.tabUsedIn,
              builder: (context) => SectionCard<MaterialUsage>(
                section: detail.usages,
                emptyMessage: i18n.noBatchesUsedIt,
                itemBuilder: (context, usage) => MaterialUsageItem(usage: usage, defaultUnit: m.unit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
