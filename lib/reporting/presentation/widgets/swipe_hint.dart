/// This file contains the Swipe Hint widget.
///
/// It is a simple UI element displayed at the bottom of the tabs to inform
/// users that they can swipe horizontally to navigate between sections.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/i18n/app_localizations.dart';

/// A small text hint that tells the user to swipe to change tabs.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        context.i18n.swipeHint, // Localized string: "Swipe to change section"
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}