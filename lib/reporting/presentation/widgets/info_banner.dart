/// This file contains the Info Banner widget.
///
/// It is used to display a subtle informational message with an icon,
/// like a note or a tip, usually at the top of a screen or section.
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// A reusable widget to display an informational message.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text});

  /// The message to display inside the banner.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // Use a very light version of the primary color for the background
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to top in case text is long
        children: [
          // Icon to draw attention
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),

          // Expanded allows the text to wrap to the next line if it's too long
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}