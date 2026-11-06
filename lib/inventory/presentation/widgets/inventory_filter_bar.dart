
import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
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
    final i18n = context.i18n;

    return switch (filter) {
      InventoryFilter.all => i18n.filterAll,
      InventoryFilter.belowMinimum => i18n.belowMinimum,
      InventoryFilter.blockedStock => i18n.blockedStock,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hint: i18n.searchMaterials,
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
