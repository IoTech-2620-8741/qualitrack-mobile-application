import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../domain/compliance.dart';
import '../bloc/notification_preferences_bloc.dart';

/// US: configure my notification preferences (in the app, by e-mail and the
/// minimum severity of alerts).
class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<NotificationPreferencesBloc>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationPreferences)),
      body: BlocConsumer<NotificationPreferencesBloc, NotificationPreferencesState>(
        listenWhen: (a, b) => a.saveStatus != b.saveStatus,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.saveStatus == PreferencesSaveStatus.saved) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.preferencesSaved)));
          } else if (state.saveStatus == PreferencesSaveStatus.failure && state.saveFailure != null) {
            messenger.showSnackBar(SnackBar(
              backgroundColor: AppColors.critical,
              content: Text(failureMessage(context, state.saveFailure!)),
            ));
          }
        },
        builder: (context, state) => RemoteStateView<NotificationPreferences>(
          state: state.remote,
          onRetry: () => bloc.add(const NotificationPreferencesRequested()),
          builder: (context, preferences) {
            final saving = state.saveStatus == PreferencesSaveStatus.saving;
            void save(NotificationPreferences value) => bloc.add(NotificationPreferencesSaved(value));
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (saving) const LinearProgressIndicator(),
                InfoCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.inAppNotifications),
                        subtitle: Text(l10n.inAppNotificationsHint),
                        value: preferences.inAppEnabled,
                        onChanged: saving ? null : (v) => save(preferences.copyWith(inAppEnabled: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.emailNotifications),
                        subtitle: Text(l10n.emailNotificationsHint),
                        value: preferences.emailEnabled,
                        onChanged: saving ? null : (v) => save(preferences.copyWith(emailEnabled: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: l10n.minimumSeverity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.minimumSeverityHint, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<AlertSeverity>(
                        segments: [
                          ButtonSegment(value: AlertSeverity.warning, label: Text(l10n.severityWarning)),
                          ButtonSegment(value: AlertSeverity.critical, label: Text(l10n.severityCritical)),
                        ],
                        selected: {
                          preferences.minimumSeverity == AlertSeverity.critical
                              ? AlertSeverity.critical
                              : AlertSeverity.warning,
                        },
                        onSelectionChanged: saving
                            ? null
                            : (selection) => save(preferences.copyWith(minimumSeverity: selection.first)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
