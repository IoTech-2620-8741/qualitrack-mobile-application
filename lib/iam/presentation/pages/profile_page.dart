import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/role_labels.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: BlocBuilder<ProfileBloc, RemoteState<ProfileData>>(
        builder: (context, state) => RemoteStateView<ProfileData>(
          state: state,
          onRetry: () => context.read<ProfileBloc>().add(const ProfileRequested()),
          builder: (context, data) {
            final account = data.account;
            final lab = data.laboratory;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      account.username.isEmpty ? '?' : account.username[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  account.username,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final role in account.roles)
                      StatusBadge(label: role.label(l10n), tone: BadgeTone.brand),
                    if (account.status != null)
                      StatusBadge(label: Formatters.humanize(account.status), tone: BadgeTone.neutral),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  title: l10n.laboratory,
                  child: data.laboratoryFailure != null
                      ? Text(failureMessage(context, data.laboratoryFailure!))
                      : lab == null
                      ? Text(l10n.noInformation)
                      : Wrap(
                          spacing: AppSpacing.xl,
                          runSpacing: AppSpacing.lg,
                          children: [
                            KeyValue(label: l10n.name, value: lab.name),
                            KeyValue(label: l10n.ruc, value: lab.ruc ?? '—'),
                            KeyValue(label: l10n.phone, value: lab.phone ?? '—'),
                            KeyValue(label: l10n.address, value: lab.address ?? '—'),
                            KeyValue(label: l10n.status, value: Formatters.humanize(lab.status)),
                            if (lab.applicableRegulations.isNotEmpty)
                              KeyValue(
                                label: l10n.regulations,
                                value: lab.applicableRegulations.join(', '),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
