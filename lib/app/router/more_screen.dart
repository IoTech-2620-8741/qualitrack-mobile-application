import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../iam/domain/entities/user_session.dart';
import '../../iam/presentation/widgets/role_labels.dart';
import '../../profile/presentation/bloc/current_profile_controller.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../common/presentation/i18n/app_localizations.dart';
import '../../common/presentation/widgets/confirm_dialog.dart';
import '../../common/presentation/widgets/layout_widgets.dart';
import '../../common/presentation/widgets/status_badge.dart';
import '../../common/presentation/theme/app_colors.dart';
import '../../common/presentation/theme/app_radius.dart';
import '../../common/presentation/theme/app_spacing.dart';
import 'app_routes.dart';

/// Secondary destinations of the app, as a native "More" tab: the user's
/// card on top, the destinations grouped in sections, and sign out at the end
/// (the same button as in the profile).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.session, required this.currentProfile, required this.onSignOut});

  final UserSession session;
  final CurrentProfileController currentProfile;
  final Future<void> Function() onSignOut;

  Future<void> _confirmSignOut(BuildContext context) async {
    final i18n = context.i18n;
    final ok = await showConfirmDialog(
      context,
      title: i18n.signOut,
      message: i18n.signOutConfirm,
      confirmLabel: i18n.signOut,
      destructive: true,
    );
    if (ok) await onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(title: i18n.more)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListenableBuilder(
            listenable: currentProfile,
            builder: (context, _) => _ProfileCard(session: session, currentProfile: currentProfile),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Sections and order of the Web menu. Telemetry, alerts and batches
          // live in the navigation bar, so Operation lists the rest.
          _MenuSection(
            title: i18n.moreOperations,
            entries: [
              _Entry(Icons.medication_outlined, i18n.moreProducts, i18n.moreProductsHint, AppRoutes.products),
              _Entry(
                Icons.precision_manufacturing_outlined,
                i18n.navEquipment,
                i18n.moreEquipmentHint,
                AppRoutes.equipment,
              ),
              _Entry(Icons.science_outlined, i18n.moreInventory, i18n.moreInventoryHint, AppRoutes.inventory),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuSection(
            title: i18n.moreQuality,
            entries: [_Entry(Icons.insights_outlined, i18n.moreReports, i18n.moreReportsHint, AppRoutes.reports)],
          ),
          // The subscription belongs to the quality manager, as in Web.
          if (session.canManageQuality) ...[
            const SizedBox(height: AppSpacing.lg),
            _MenuSection(
              title: i18n.moreAdministration,
              entries: [_Entry(Icons.receipt_long_outlined, i18n.moreBilling, i18n.moreBillingHint, AppRoutes.billing)],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _MenuSection(
            title: i18n.moreAccount,
            entries: [
              _Entry(
                Icons.notifications_outlined,
                i18n.notificationsTitle,
                i18n.moreNotificationsHint,
                AppRoutes.notifications,
              ),
              _Entry(Icons.info_outline, i18n.about, i18n.moreAboutHint, AppRoutes.about),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Same button as the profile screen.
          OutlinedButton.icon(
            key: const Key('more.signOut'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            label: Text(i18n.signOut),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'QualiTrack Mobile · ${i18n.versionLabel(AboutScreen.version)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The signed-in user: avatar, name, role; opens the profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.session, required this.currentProfile});

  final UserSession session;
  final CurrentProfileController currentProfile;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final profile = currentProfile.profile;
    final name = profile?.displayName ?? session.username;
    final role = session.primaryRole?.label(i18n);
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.profile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              ProfileAvatar(
                photo: currentProfile.photo,
                radius: 28,
                initials: profile?.initials ?? (session.username.isEmpty ? '?' : session.username[0].toUpperCase()),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
                    ),
                    if (profile?.email != null)
                      Text(profile!.email!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                    if (role != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      StatusBadge(label: role, tone: BadgeTone.brand),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination of the menu.
final class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

/// A titled group of destinations on one rounded surface.
class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.entries});

  final String title;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InfoCard(
      title: title,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              minVerticalPadding: AppSpacing.sm + AppSpacing.xxs,
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: Icon(entries[i].icon, size: 22, color: AppColors.primaryDark),
              ),
              title: Text(
                entries[i].title,
                style: text.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(entries[i].subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => context.push(entries[i].route),
            ),
          ],
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(title: i18n.about)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Icon(Icons.verified_user_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('QualiTrack Mobile', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          Text(i18n.versionLabel(version), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(i18n.aboutDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(i18n.aboutWebScope, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Text(i18n.copyright, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
