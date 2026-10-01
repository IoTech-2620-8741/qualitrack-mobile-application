import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../widgets/qualitrack_logo.dart';

/// Shown while the stored session is being validated. Navigation happens in
/// the router redirect as soon as [SessionController] resolves.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QualiTrackLogo(size: 120),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              label: context.l10n.checkingSession,
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
