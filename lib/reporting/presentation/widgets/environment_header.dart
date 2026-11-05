/// This file contains the Environment Header widget.
///
/// It is used as a section title to group data by environment
/// (e.g., in the Measurements screen).
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// A simple header widget that displays the environment name in uppercase.
class EnvironmentHeader extends StatelessWidget {
  const EnvironmentHeader({super.key, required this.name});

  /// The name of the environment to display.
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Add spacing above and below to separate it from other items in the list
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
        left: 4, // Small offset to align with text inputs below
      ),
      child: Text(
        name.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.5, // Makes it look cleaner and more readable
        ),
      ),
    );
  }
}