import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/notification_preferences.dart';
import '../bloc/notification_preferences_bloc.dart';

/// US: configure my notification preferences (in the app, by e-mail and the
/// minimum severity of alerts).
class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<NotificationPreferencesBloc>();
    return Scaffold(
      appBar: AppBar(title: Text(i18n.notificationPreferences)),
      body: BlocConsumer<NotificationPreferencesBloc, NotificationPreferencesState>(
        listenWhen: (a, b) => a.saveStatus != b.saveStatus,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.saveStatus == PreferencesSaveStatus.saved) {
            messenger.showSnackBar(SnackBar(content: Text(i18n.preferencesSaved)));
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
          onRefresh: () => bloc.add(const NotificationPreferencesRequested()),
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
                        title: Text(i18n.inAppNotifications),
                        subtitle: Text(i18n.inAppNotificationsHint),
                        value: preferences.inAppEnabled,
                        onChanged: saving ? null : (v) => save(preferences.copyWith(inAppEnabled: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(i18n.emailNotifications),
                        subtitle: Text(i18n.emailNotificationsHint),
                        value: preferences.emailEnabled,
                        onChanged: saving ? null : (v) => save(preferences.copyWith(emailEnabled: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: i18n.minimumSeverity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(i18n.minimumSeverityHint, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<AlertSeverity>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: AlertSeverity.warning, label: Text(i18n.severityWarning)),
                          ButtonSegment(value: AlertSeverity.critical, label: Text(i18n.severityCritical)),
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
