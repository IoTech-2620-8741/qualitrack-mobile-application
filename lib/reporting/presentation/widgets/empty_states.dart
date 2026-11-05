/// This file contains the reusable Empty State widget.
///
/// It is used across the app to display a friendly message (and an optional
/// action button) when there is no data to show.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_spacing.dart';

/// A reusable widget to display an empty state.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  /// The icon to display at the top.
  final IconData icon;

  /// The main message to display.
  final String message;

  /// Optional callback triggered when the action button is pressed.
  final VoidCallback? onAction;

  /// Optional label for the action button.
  /// If [onAction] is null, this button will not be displayed.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Icon with a subtle transparency to not be too aggressive
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. The main message
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),

          // 3. Optional action button (only shown if both callback and label exist)
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}