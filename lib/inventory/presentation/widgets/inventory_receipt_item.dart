
import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';

import '../../domain/entities/inventory_receipt.dart';
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
    final i18n = context.i18n;
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
              i18n.receiptNumber(receipt.id),
          subtitle:
              '${i18n.supplier}: ${receipt.supplier ?? '—'}',
          trailing: StatusBadge(
            label: receipt.status.label(i18n),
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
              label: i18n.initialAmount,
              value: quantity(
                receipt.initialAmount,
                receipt.unit,
              ),
            ),

            KeyValue(
              label: i18n.availableAmount,
              value: quantity(
                receipt.availableAmount,
                receipt.unit,
              ),
            ),

            KeyValue(
              label: i18n.receivedOn,
              value: Formatters.date(
                receipt.receivedOn,
                locale,
              ),
            ),

            KeyValue(
              label: i18n.expiresOn,
              value: Formatters.date(
                receipt.expiresOn,
                locale,
              ),
            ),

            // Disponibilidad del lote
            KeyValue(
              label: i18n.usable,
              value: receipt.usable
                  ? i18n.yes
                  : i18n.no,
              valueWidget: StatusBadge(
                label: receipt.usable
                    ? i18n.yes
                    : lotAvailabilityLabel(
                        i18n,
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
                    ? i18n.lotExpired
                    : i18n.lotNearExpiry,
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
