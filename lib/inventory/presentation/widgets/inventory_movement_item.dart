
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../domain/inventory.dart';
import 'inventory_labels.dart';

/// Displays an inventory movement with its stock changes,
/// status transitions and related production batch.
class InventoryMovementItem extends StatelessWidget {
  const InventoryMovementItem({
    super.key,
    required this.movement,
    required this.defaultUnit,
  });

  final InventoryMovement movement;
  final String defaultUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;

    String quantity(double? value, [String? unit]) {
      return '${Formatters.number(value, locale)} ${unit ?? defaultUnit}'
          .trim();
    }

    final details = <String>[
      if (movement.amount != null)
        quantity(movement.amount, movement.unit),

      if (movement.stockBefore != null ||
          movement.stockAfter != null)
        l10n.stockBeforeAfter(
          Formatters.number(movement.stockBefore, locale),
          Formatters.number(movement.stockAfter, locale),
        ),

      if (movement.statusBefore != null ||
          movement.statusAfter != null)
        '${Formatters.humanize(movement.statusBefore)} → '
        '${Formatters.humanize(movement.statusAfter)}',

      if (movement.reason != null &&
          movement.reason!.isNotEmpty)
        movement.reason!,
    ];

    return SectionRow(
      title: movementTypeLabel(l10n, movement.type),
      subtitle: details.join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.dateTime(movement.occurredAt, locale),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (movement.productBatchId != null)
            TextButton(
              onPressed: () => context.push(
                '/batches/${movement.productBatchId}',
              ),
              child: Text(
                l10n.batchNumberShort(
                  movement.productBatchId!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
