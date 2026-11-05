import 'package:flutter/material.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';

class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        context.l10n.swipeHint,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
      ),
    );
  }
}