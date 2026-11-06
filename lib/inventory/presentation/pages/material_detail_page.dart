import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/inventory.dart';
import '../bloc/material_detail_bloc.dart';
import '../widgets/inventory_labels.dart';
import '../widgets/inventory_receipt_item.dart';
import '../widgets/inventory_movement_item.dart';
import '../widgets/material_usage_item.dart';

class MaterialDetailPage extends StatelessWidget {
  const MaterialDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<MaterialDetailBloc>().add(const MaterialDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.materialDetail)),
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
    final l10n = context.l10n;
    final locale = context.localeName;
    final m = detail.material;
    String qty(double? v, [String? unit]) =>
        '${Formatters.number(v, locale)} ${unit ?? m.unit}'.trim();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(
          title: m.name,
          subtitle: m.code,
          trailing: StatusBadge(label: m.stockLabel(l10n), tone: m.stockTone),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              if (detail.environmentName != null) KeyValue(label: l10n.environment, value: detail.environmentName!),
              KeyValue(label: l10n.unit, value: m.unit.isEmpty ? '—' : m.unit),
              KeyValue(label: l10n.usableStock, value: qty(m.usableStock)),
              KeyValue(label: l10n.physicalStock, value: qty(m.physicalStock)),
              KeyValue(label: l10n.minimumStock, value: qty(m.minimumStock)),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        SectionCard<InventoryReceipt>(
          title: l10n.materialLots,
          section: detail.receipts,
          emptyMessage: l10n.receiptsEmpty,
          itemBuilder: (context, receipt) => InventoryReceiptItem(
            receipt: receipt,
            defaultUnit: m.unit,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        SectionCard<InventoryMovement>(
          title: l10n.movements,
          section: detail.movements,
          emptyMessage: l10n.movementsEmpty,
          itemBuilder: (context, movement) => InventoryMovementItem(
            movement: movement,
            defaultUnit: m.unit,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<MaterialUsage>(
          title: l10n.batchesThatUsedIt,
          section: detail.usages,
          emptyMessage: l10n.noBatchesUsedIt,
          itemBuilder: (context, usage) => MaterialUsageItem(
            usage: usage,
            defaultUnit: m.unit,
          ),
        ),
      ],
    );
  }
}
