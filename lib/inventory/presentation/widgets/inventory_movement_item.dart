
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../domain/entities/inventory_movement.dart';
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
    final i18n = context.i18n;
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
        i18n.stockBeforeAfter(
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
      title: movementTypeLabel(i18n, movement.type),
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
                i18n.batchNumberShort(
                  movement.productBatchId!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
