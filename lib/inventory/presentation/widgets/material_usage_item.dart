
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../domain/inventory.dart';

/// Displays a raw material consumption associated
/// with a production batch.
class MaterialUsageItem extends StatelessWidget {
  const MaterialUsageItem({
    super.key,
    required this.usage,
    required this.defaultUnit,
  });

  final MaterialUsage usage;
  final String defaultUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;

    String quantity(double? value, String? unit) {
      return '${Formatters.number(value, locale)} ${unit ?? defaultUnit}'
          .trim();
    }

    return SectionRow(
      leading: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      title: l10n.batchNumberShort(usage.batchId),
      subtitle: Formatters.dateTime(
        usage.usageDate,
        locale,
      ),
      trailing: TextButton(
        onPressed: () => context.push(
          '/batches/${usage.batchId}',
        ),
        child: Text(
          quantity(
            usage.quantityUsed,
            usage.unit,
          ),
        ),
      ),
    );
  }
}
