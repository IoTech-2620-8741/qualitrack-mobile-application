
import 'package:flutter/material.dart';

import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../domain/entities/inventory_material.dart';

/// Displays the usable, physical and minimum stock quantities.
///
/// The layout adapts to the available horizontal space.
/// Quantity values are provided by InventoryMaterial.
class InventoryStockQuantities extends StatelessWidget {
  /// Creates a responsive stock quantity section.
  const InventoryStockQuantities({
    super.key,
    required this.material,
  });

  /// Raw material containing the stock quantities.
  final InventoryMaterial material;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;

    String quantity(double value) {
      return '${Formatters.number(value, locale)} '
              '${material.unit}'
          .trim();
    }

    final fields = [
      KeyValue(
        label: i18n.usableStock,
        value: quantity(material.usableStock),
      ),
      KeyValue(
        label: i18n.physicalStock,
        value: quantity(material.physicalStock),
      ),
      KeyValue(
        label: i18n.minimumStock,
        value: quantity(material.minimumStock),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const minimumItemWidth = 130.0;
        const spacing = AppSpacing.md;

        final columns = ((constraints.maxWidth + spacing) /
                (minimumItemWidth + spacing))
            .floor()
            .clamp(1, 3)
            .toInt();

        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) /
            columns;

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.md,
          children: [
            for (final field in fields)
              SizedBox(
                width: itemWidth,
                child: field,
              ),
          ],
        );
      },
    );
  }
}
