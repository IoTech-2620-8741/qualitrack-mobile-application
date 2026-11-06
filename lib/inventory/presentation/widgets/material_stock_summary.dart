
import 'package:flutter/material.dart';
import 'package:qualitrack_mobile/shared/presentation/l10n/app_localizations.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../domain/inventory.dart';

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
    final l10n = context.l10n;
    final locale = context.localeName;

    String quantity(double value) {
      return '${Formatters.number(value, locale)} ${material.unit}'.trim();
    }

    return InfoCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          if (environmentName != null)
            KeyValue(
              label: l10n.environment,
              value: environmentName!,
            ),
          KeyValue(
            label: l10n.unit,
            value: material.unit.isEmpty ? '—' : material.unit,
          ),
          KeyValue(
            label: l10n.usableStock,
            value: quantity(material.usableStock),
          ),
          KeyValue(
            label: l10n.physicalStock,
            value: quantity(material.physicalStock),
          ),
          KeyValue(
            label: l10n.minimumStock,
            value: quantity(material.minimumStock),
          ),
        ],
      ),
    );
  }
}
