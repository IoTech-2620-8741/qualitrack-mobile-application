/// This file contains the Modern Card widget.
///
/// It is a highly reusable container that applies a consistent visual style
/// (rounded corners, subtle shadow, and a slight border) to its children.
/// It also handles tap interactions with an ink ripple effect.
///
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

/// A reusable, styled card widget with tap interaction support.
class ModernCard extends StatelessWidget {
  const ModernCard({super.key, required this.child, this.onTap});

  /// The widget to display inside the card.
  final Widget child;

  /// Optional callback triggered when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Add a bottom margin to separate it from the next card in the list
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // A very subtle shadow to give it a floating appearance without being overwhelming
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // A faint border helps define the card's edges on white backgrounds
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Material(
        // Material is required to show the InkWell ripple effect properly on top of a Container
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}