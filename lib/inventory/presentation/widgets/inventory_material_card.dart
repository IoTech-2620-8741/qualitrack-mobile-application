import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/status_badge.dart';

import '../../domain/inventory.dart';
import 'inventory_labels.dart';

class InventoryMaterialCard extends StatelessWidget {
  const InventoryMaterialCard({
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
    final theme = Theme.of(context);

    String quantity(double value) {
      return '${Formatters.number(value, locale)} ${material.unit}'
          .trim();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/inventory/${material.id}'
          '?environmentId=${material.environmentId}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: material.code,
                                style: const TextStyle(
                                  fontFamily:
                                      AppTypography.monospace,
                                ),
                              ),
                              if (environmentName != null)
                                TextSpan(
                                  text: ' · $environmentName',
                                ),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: material.stockLabel(l10n),
                    tone: material.stockTone,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: KeyValue(
                      label: l10n.usableStock,
                      value: quantity(material.usableStock),
                    ),
                  ),
                  Expanded(
                    child: KeyValue(
                      label: l10n.physicalStock,
                      value: quantity(material.physicalStock),
                    ),
                  ),
                  Expanded(
                    child: KeyValue(
                      label: l10n.minimumStock,
                      value: quantity(material.minimumStock),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}