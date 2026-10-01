import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              KeyValue(label: l10n.unit, value: m.unit.isEmpty ? '—' : m.unit),
              KeyValue(label: l10n.usableStock, value: qty(m.usableStock)),
              KeyValue(label: l10n.physicalStock, value: qty(m.physicalStock)),
              KeyValue(label: l10n.minimumStock, value: qty(m.minimumStock)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<InventoryReceipt>(
          title: l10n.receipts,
          section: detail.receipts,
          emptyMessage: l10n.receiptsEmpty,
          itemBuilder: (context, r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionRow(
                title: r.batchNumber ?? l10n.receiptNumber(r.id),
                subtitle: '${l10n.supplier}: ${r.supplier ?? '—'}',
                trailing: StatusBadge(label: r.status.label(l10n), tone: r.status.tone),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  KeyValue(label: l10n.initialAmount, value: qty(r.initialAmount, r.unit)),
                  KeyValue(label: l10n.availableAmount, value: qty(r.availableAmount, r.unit)),
                  KeyValue(label: l10n.receivedOn, value: Formatters.date(r.receivedOn, locale)),
                  KeyValue(label: l10n.expiresOn, value: Formatters.date(r.expiresOn, locale)),
                  KeyValue(
                    label: l10n.usable,
                    value: r.usable ? l10n.yes : l10n.no,
                    valueWidget: StatusBadge(
                      label: r.usable ? l10n.yes : (r.availability ?? l10n.no),
                      tone: r.usable ? BadgeTone.success : BadgeTone.neutral,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<InventoryMovement>(
          title: l10n.movements,
          section: detail.movements,
          emptyMessage: l10n.movementsEmpty,
          itemBuilder: (context, mv) {
            final details = <String>[
              if (mv.amount != null) qty(mv.amount, mv.unit),
              if (mv.stockBefore != null || mv.stockAfter != null)
                l10n.stockBeforeAfter(
                  Formatters.number(mv.stockBefore, locale),
                  Formatters.number(mv.stockAfter, locale),
                ),
              if (mv.statusBefore != null || mv.statusAfter != null)
                '${Formatters.humanize(mv.statusBefore)} → ${Formatters.humanize(mv.statusAfter)}',
              if (mv.reason != null && mv.reason!.isNotEmpty) mv.reason!,
            ];
            return SectionRow(
              title: Formatters.humanize(mv.type),
              subtitle: details.join(' · '),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.dateTime(mv.occurredAt, locale), style: Theme.of(context).textTheme.bodySmall),
                  if (mv.productBatchId != null)
                    TextButton(
                      onPressed: () => context.push('/batches/${mv.productBatchId}'),
                      child: Text(l10n.batchNumberShort(mv.productBatchId!)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
