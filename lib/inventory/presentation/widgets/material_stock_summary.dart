
import 'package:flutter/material.dart';
import '../../../common/presentation/i18n/app_localizations.dart';

import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../domain/entities/inventory_material.dart';
import 'inventory_stock_quantities.dart';

/// Displays stock quantities and catalog information
/// for a raw material.
class MaterialStockSummary extends StatelessWidget {
  const MaterialStockSummary({
    super.key,
    required this.material,
    this.environmentName,
  });

  final InventoryMaterial material;
  final String? environmentName;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              if (environmentName != null)
                KeyValue(
                  label: i18n.environment,
                  value: environmentName!,
                ),
              KeyValue(
                label: i18n.unit,
                value: material.unit.isEmpty
                    ? '—'
                    : material.unit,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          InventoryStockQuantities(material: material),
        ],
      ),
    );
  }
}
