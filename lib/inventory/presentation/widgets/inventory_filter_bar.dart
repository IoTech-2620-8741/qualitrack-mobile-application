
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../bloc/inventory_bloc.dart';

/// Displays the search field and stock filters
/// used by the inventory catalog.
///
/// Filtering logic remains in InventoryBloc.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  /// Currently selected inventory filter.
  final InventoryFilter selectedFilter;

  /// Callback triggered when the search text changes.
  final ValueChanged<String> onQueryChanged;

  /// Callback triggered when a stock filter is selected.
  final ValueChanged<InventoryFilter> onFilterChanged;

  /// Returns the localized label of an inventory filter.
  String _filterLabel(
    BuildContext context,
    InventoryFilter filter,
  ) {
    final l10n = context.l10n;

    return switch (filter) {
      InventoryFilter.all => l10n.filterAll,
      InventoryFilter.belowMinimum => l10n.belowMinimum,
      InventoryFilter.blockedStock => l10n.blockedStock,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hint: l10n.searchMaterials,
          onChanged: onQueryChanged,
        ),

        const SizedBox(height: AppSpacing.sm),

        FilterChipBar<InventoryFilter>(
          options: InventoryFilter.values,
          selected: selectedFilter,
          labelOf: (filter) => _filterLabel(
            context,
            filter,
          ),
          onSelected: onFilterChanged,
        ),
      ],
    );
  }
}
