/// This file contains the Modern Filter Chip and the Chip Bar.
///
/// They are highly reusable UI components used to display selectable
/// filters in a modern, pill-shaped style with horizontal scrolling.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';

/// A single modern, pill-shaped filter chip.
class ModernFilterChip extends StatelessWidget {
  const ModernFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  /// The text to display inside the chip.
  final String label;

  /// Whether the chip is currently selected or not.
  final bool selected;

  /// Callback triggered when the user taps the chip.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add margin to separate it from the next chip
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),

        // Styling
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}

/// A horizontally scrollable bar that contains multiple [ModernFilterChip]s.
class ModernFilterChipBar extends StatelessWidget {
  const ModernFilterChipBar({super.key, required this.children});

  /// The list of chips to display inside the bar.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}