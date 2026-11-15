
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../domain/entities/material_usage.dart';

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
    final i18n = context.i18n;
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
      title: i18n.batchNumberShort(usage.batchId),
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
