/// This file contains the Modern Card widget.
///
/// It is a reusable container with the same look as every other card in the
/// app (white surface, 16dp corners, no border or shadow) and the Material
/// ripple when tapped.
library;

import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';

/// A reusable, styled card widget with tap interaction support.
class ModernCard extends StatelessWidget {
  const ModernCard({super.key, required this.child, this.onTap});

  /// The widget to display inside the card.
  final Widget child;

  /// Optional callback triggered when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Separates it from the next card in the list.
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
