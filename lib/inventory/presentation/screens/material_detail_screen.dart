import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_receipt.dart';
import '../../domain/entities/material_usage.dart';
import '../bloc/material_detail_bloc.dart';
import '../widgets/inventory_labels.dart';

class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<MaterialDetailBloc>().add(const MaterialDetailRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(i18n.materialDetail)),
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
          trailing: StatusBadge(label: m.stockLabel(i18n), tone: m.stockTone),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              if (detail.environmentName != null) KeyValue(label: i18n.environment, value: detail.environmentName!),
              KeyValue(label: i18n.unit, value: m.unit.isEmpty ? '—' : m.unit),
              KeyValue(label: i18n.usableStock, value: qty(m.usableStock)),
              KeyValue(label: i18n.physicalStock, value: qty(m.physicalStock)),
              KeyValue(label: i18n.minimumStock, value: qty(m.minimumStock)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<InventoryReceipt>(
          title: i18n.materialLots,
          section: detail.receipts,
          emptyMessage: i18n.receiptsEmpty,
          itemBuilder: (context, r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionRow(
                title: r.batchNumber ?? i18n.receiptNumber(r.id),
                subtitle: '${i18n.supplier}: ${r.supplier ?? '—'}',
                trailing: StatusBadge(label: r.status.label(i18n), tone: r.status.tone),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  KeyValue(label: i18n.initialAmount, value: qty(r.initialAmount, r.unit)),
                  KeyValue(label: i18n.availableAmount, value: qty(r.availableAmount, r.unit)),
                  KeyValue(label: i18n.receivedOn, value: Formatters.date(r.receivedOn, locale)),
                  KeyValue(label: i18n.expiresOn, value: Formatters.date(r.expiresOn, locale)),
                  KeyValue(
                    label: i18n.usable,
                    value: r.usable ? i18n.yes : i18n.no,
                    valueWidget: StatusBadge(
                      label: r.usable ? i18n.yes : lotAvailabilityLabel(i18n, r.availability),
                      tone: r.usable ? BadgeTone.success : BadgeTone.neutral,
                    ),
                  ),
                  if (r.isNearExpiry || r.isExpired)
                    StatusBadge(
                      label: r.isExpired ? i18n.lotExpired : i18n.lotNearExpiry,
                      tone: r.isExpired ? BadgeTone.critical : BadgeTone.warning,
                      icon: Icons.event_busy_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<InventoryMovement>(
          title: i18n.movements,
          section: detail.movements,
          emptyMessage: i18n.movementsEmpty,
          itemBuilder: (context, mv) {
            final details = <String>[
              if (mv.amount != null) qty(mv.amount, mv.unit),
              if (mv.stockBefore != null || mv.stockAfter != null)
                i18n.stockBeforeAfter(
                  Formatters.number(mv.stockBefore, locale),
                  Formatters.number(mv.stockAfter, locale),
                ),
              if (mv.statusBefore != null || mv.statusAfter != null)
                '${Formatters.humanize(mv.statusBefore)} → ${Formatters.humanize(mv.statusAfter)}',
              if (mv.reason != null && mv.reason!.isNotEmpty) mv.reason!,
            ];
            return SectionRow(
              title: movementTypeLabel(i18n, mv.type),
              subtitle: details.join(' · '),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.dateTime(mv.occurredAt, locale), style: Theme.of(context).textTheme.bodySmall),
                  if (mv.productBatchId != null)
                    TextButton(
                      onPressed: () => context.push('/batches/${mv.productBatchId}'),
                      child: Text(i18n.batchNumberShort(mv.productBatchId!)),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<MaterialUsage>(
          title: i18n.batchesThatUsedIt,
          section: detail.usages,
          emptyMessage: i18n.noBatchesUsedIt,
          itemBuilder: (context, u) => SectionRow(
            leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
            title: i18n.batchNumberShort(u.batchId),
            subtitle: Formatters.dateTime(u.usageDate, locale),
            trailing: TextButton(
              onPressed: () => context.push('/batches/${u.batchId}'),
              child: Text(qty(u.quantityUsed, u.unit)),
            ),
          ),
        ),
      ],
    );
  }
}
