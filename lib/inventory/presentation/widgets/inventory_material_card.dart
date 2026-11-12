import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';

import '../../../common/presentation/i18n/app_localizations.dart';

import '../../../common/presentation/widgets/status_badge.dart';
import 'inventory_stock_quantities.dart';

import '../../domain/entities/inventory_material.dart';
import 'inventory_labels.dart';

class InventoryMaterialCard extends StatelessWidget {
  const InventoryMaterialCard({super.key, required this.material, this.environmentName});

  final InventoryMaterial material;
  final String? environmentName;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => context.push(
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
                  // Mobile list item: tonal leading icon tinted by the stock level.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: material.stockTone.background, shape: BoxShape.circle),
                    child: Icon(Icons.science_outlined, size: 22, color: material.stockTone.foreground),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: material.code,
                                style: const TextStyle(fontFamily: AppTypography.monospace),
                              ),
                              if (environmentName != null) TextSpan(text: ' · $environmentName'),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: material.stockLabel(i18n), tone: material.stockTone),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              InventoryStockQuantities(material: material),
            ],
          ),
        ),
      ),
    );
  }
}
