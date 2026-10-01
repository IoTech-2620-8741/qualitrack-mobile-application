import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../iam/domain/user_session.dart';
import '../../iam/presentation/widgets/role_labels.dart';
import '../../shared/presentation/l10n/app_localizations.dart';
import '../../shared/presentation/widgets/confirm_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_routes.dart';

/// "Navigation Menu" mockup: secondary destinations of the app.
class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.session, required this.onSignOut});

  final UserSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = <(IconData, String, String)>[
      (Icons.science_outlined, l10n.inventoryTitle, AppRoutes.inventory),
      (Icons.precision_manufacturing_outlined, l10n.equipmentTitle, AppRoutes.equipment),
      (Icons.medication_outlined, l10n.productsTitle, AppRoutes.products),
      (Icons.insights_outlined, l10n.reportsTitle, AppRoutes.reports),
      (Icons.receipt_long_outlined, l10n.billingTitle, AppRoutes.billing),
      (Icons.person_outline, l10n.profile, AppRoutes.profile),
      (Icons.info_outline, l10n.about, AppRoutes.about),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                session.username.isEmpty ? '?' : session.username[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(session.username, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(session.primaryRole?.label(l10n) ?? '—'),
          ),
          const Divider(),
          for (final (icon, label, route) in entries)
            ListTile(
              leading: Icon(icon, color: AppColors.primary),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(route),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.critical),
            title: Text(l10n.signOut, style: const TextStyle(color: AppColors.critical)),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l10n.signOut,
                message: l10n.signOutConfirm,
                confirmLabel: l10n.signOut,
                destructive: true,
              );
              if (ok) await onSignOut();
            },
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Icon(Icons.verified_user_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('QualiTrack Mobile', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          Text(l10n.versionLabel(version), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.aboutDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aboutWebScope, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('© IoTech · ClosedSource', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
