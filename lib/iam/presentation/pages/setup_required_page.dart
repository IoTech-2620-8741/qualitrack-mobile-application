import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../application/session_controller.dart';
import '../../domain/onboarding_state.dart';
import '../widgets/qualitrack_logo.dart';

/// Shown when the account has no laboratory or no active subscription.
/// Setup is performed exclusively in QualiTrack Web.
class SetupRequiredPage extends StatefulWidget {
  const SetupRequiredPage({super.key, required this.session});

  final SessionController session;

  @override
  State<SetupRequiredPage> createState() => _SetupRequiredPageState();
}

class _SetupRequiredPageState extends State<SetupRequiredPage> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    await widget.session.recheck();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final step = widget.session.pendingStep;
    final reason = switch (step) {
      OnboardingStep.subscription => l10n.setupSubscriptionMissing,
      OnboardingStep.laboratory => l10n.setupLaboratoryMissing,
      _ => l10n.setupGeneric,
    };
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const QualiTrackLogo(size: 90),
              const SizedBox(height: AppSpacing.xl),
              const Icon(Icons.desktop_windows_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  l10n.setupRequiredTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(reason, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.setupRequiredHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _checking ? null : _recheck,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.checkAgain),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _checking ? null : widget.session.signOut,
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
