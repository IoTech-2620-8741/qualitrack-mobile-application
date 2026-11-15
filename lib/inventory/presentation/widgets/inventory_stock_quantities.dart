import 'package:flutter/material.dart';

import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/inventory_material.dart';
import 'inventory_labels.dart';

/// Usable, physical and minimum stock of a material, as on a mobile card:
/// a bar that shows the usable stock against the physical one (with a tick
/// at the minimum) and the three amounts on one row below it.
class InventoryStockQuantities extends StatelessWidget {
  const InventoryStockQuantities({super.key, required this.material});

  final InventoryMaterial material;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final text = Theme.of(context).textTheme;
    String quantity(double value) => '${Formatters.number(value, locale)} ${material.unit}'.trim();

    final scale = [material.physicalStock, material.minimumStock, material.usableStock, 1.0].reduce(
      (a, b) => a > b ? a : b,
    );
    final usable = (material.usableStock / scale).clamp(0.0, 1.0);
    final minimum = (material.minimumStock / scale).clamp(0.0, 1.0);
    final tone = material.stockTone;
    final barColor = tone == BadgeTone.neutral ? AppColors.primary : tone.foreground;

    Widget amount(String label, String value) => Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.neutralContainer, borderRadius: AppRadius.pillAll),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * usable,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: barColor, borderRadius: AppRadius.pillAll),
                    ),
                  ),
                  // Tick at the minimum stock.
                  Positioned(
                    left: (constraints.maxWidth * minimum - 1).clamp(0.0, constraints.maxWidth - 2),
                    top: -3,
                    bottom: -3,
                    width: 2,
                    child: const ColoredBox(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            amount(i18n.usableStock, quantity(material.usableStock)),
            const SizedBox(width: AppSpacing.sm),
            amount(i18n.physicalStock, quantity(material.physicalStock)),
            const SizedBox(width: AppSpacing.sm),
            amount(i18n.minimumStock, quantity(material.minimumStock)),
          ],
        ),
      ],
    );
  }
}
