
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';

import '../../domain/inventory.dart';
import 'inventory_labels.dart';

class InventoryReceiptItem extends StatelessWidget {
  const InventoryReceiptItem({
    super.key,
    required this.receipt,
    required this.defaultUnit,
  });

  final InventoryReceipt receipt;
  final String defaultUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;

    String quantity(double? value, String? unit) {
      return '${Formatters.number(value, locale)} ${unit ?? defaultUnit}'
          .trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Información principal del lote
        SectionRow(
          title: receipt.batchNumber ??
              l10n.receiptNumber(receipt.id),
          subtitle:
              '${l10n.supplier}: ${receipt.supplier ?? '—'}',
          trailing: StatusBadge(
            label: receipt.status.label(l10n),
            tone: receipt.status.tone,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Información de cantidades, fechas y disponibilidad
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            KeyValue(
              label: l10n.initialAmount,
              value: quantity(
                receipt.initialAmount,
                receipt.unit,
              ),
            ),

            KeyValue(
              label: l10n.availableAmount,
              value: quantity(
                receipt.availableAmount,
                receipt.unit,
              ),
            ),

            KeyValue(
              label: l10n.receivedOn,
              value: Formatters.date(
                receipt.receivedOn,
                locale,
              ),
            ),

            KeyValue(
              label: l10n.expiresOn,
              value: Formatters.date(
                receipt.expiresOn,
                locale,
              ),
            ),

            // Disponibilidad del lote
            KeyValue(
              label: l10n.usable,
              value: receipt.usable
                  ? l10n.yes
                  : l10n.no,
              valueWidget: StatusBadge(
                label: receipt.usable
                    ? l10n.yes
                    : lotAvailabilityLabel(
                        l10n,
                        receipt.availability,
                      ),
                tone: receipt.usable
                    ? BadgeTone.success
                    : BadgeTone.neutral,
              ),
            ),

            // Advertencia por vencimiento
            if (receipt.isNearExpiry || receipt.isExpired)
              StatusBadge(
                label: receipt.isExpired
                    ? l10n.lotExpired
                    : l10n.lotNearExpiry,
                tone: receipt.isExpired
                    ? BadgeTone.critical
                    : BadgeTone.warning,
                icon: Icons.event_busy_outlined,
              ),
          ],
        ),
      ],
    );
  }
}
