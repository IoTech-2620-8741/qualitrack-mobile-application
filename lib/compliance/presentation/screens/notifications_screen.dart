import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';
import '../bloc/notifications_bloc.dart';

/// In-app notices (US: receive notices in the app). Opening one marks it as
/// read and leads to the alert or the batch.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<NotificationsBloc>();
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.actionFailure != b.actionFailure && b.actionFailure != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.critical,
        content: Text(failureMessage(context, state.actionFailure!)),
      )),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: AppBarTitle(title: i18n.notificationsTitle),
          actions: [
            IconButton(
              tooltip: i18n.markAllRead,
              onPressed: state.unread == 0 ? null : () => bloc.add(const NotificationsAllRead()),
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              tooltip: i18n.notificationPreferences,
              onPressed: () => context.push('/profile/notifications'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: RemoteStateView<List<AppNotification>>(
          state: state.remote,
          onRetry: () => bloc.add(const NotificationsRequested()),
          emptyIcon: Icons.notifications_none,
          emptyMessage: i18n.notificationsEmpty,
          builder: (context, items) => RefreshIndicator(
            onRefresh: () async => bloc.add(const NotificationsRequested(refresh: true)),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _NotificationTile(notification: items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text of a notice, worded as in QualiTrack Web.
String notificationText(AppLocalizations i18n, AppNotification n, String locale) {
  final environment = n.environmentName ?? i18n.anEnvironment;
  final variable = alertVariable(i18n, n.parameterName ?? '');
  final value = n.recordedValue == null ? '—' : Formatters.number(n.recordedValue, locale);
  final unit = n.unit ?? '';
  final actor = n.actorName ?? i18n.someone;
  final text = switch (n.type) {
    NotificationType.alertOpened => i18n.noticeAlertOpened(_severityWord(i18n, n.severity), environment, variable, value, unit),
    NotificationType.alertEscalated => i18n.noticeAlertEscalated(variable, environment, _levelWord(i18n, n.severity), value, unit),
    NotificationType.alertAcknowledged => i18n.noticeAlertAcknowledged(actor, variable, environment),
    NotificationType.alertResolved => i18n.noticeAlertResolved(actor, variable, environment),
    NotificationType.batchReleased => i18n.noticeBatchReleased(actor, n.subjectName ?? '#${n.subjectId}'),
    NotificationType.batchRejected => i18n.noticeBatchRejected(actor, n.subjectName ?? '#${n.subjectId}', n.note ?? ''),
    NotificationType.unknown => n.note ?? n.subjectName ?? '',
  };
  return text.replaceAll(RegExp(r'\s+\.'), '.').trim();
}

/// "critical" in "New critical alert in …".
String _severityWord(AppLocalizations i18n, AlertSeverity severity) => switch (severity) {
  AlertSeverity.low => i18n.noticeSeverityLow,
  AlertSeverity.critical => i18n.noticeSeverityCritical,
  _ => i18n.noticeSeverityWarning,
};

/// "critical" in "… rose to critical".
String _levelWord(AppLocalizations i18n, AlertSeverity severity) => switch (severity) {
  AlertSeverity.low => i18n.noticeLevelLow,
  AlertSeverity.critical => i18n.noticeLevelCritical,
  _ => i18n.noticeLevelWarning,
};

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon => switch (notification.type) {
    // Same icon as the alerts everywhere else (More menu, navigation).
    NotificationType.alertOpened || NotificationType.alertEscalated => Icons.report_problem_outlined,
    NotificationType.alertAcknowledged => Icons.visibility_outlined,
    NotificationType.alertResolved => Icons.task_alt,
    NotificationType.batchReleased => Icons.verified_outlined,
    NotificationType.batchRejected => Icons.block,
    NotificationType.unknown => Icons.notifications_outlined,
  };

  Color get _color => switch (notification.type) {
    NotificationType.alertOpened || NotificationType.alertEscalated =>
      notification.severity == AlertSeverity.critical ? AppColors.critical : AppColors.warning,
    NotificationType.alertResolved || NotificationType.batchReleased => AppColors.success,
    NotificationType.batchRejected => AppColors.critical,
    _ => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final n = notification;
    final theme = Theme.of(context);
    // Unread = bold text + the "Unread" badge; no tinted background on top.
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withValues(alpha: 0.12),
        child: Icon(_icon, color: _color),
      ),
      title: Text(
        notificationText(i18n, n, locale),
        style: n.isRead ? theme.textTheme.bodyMedium : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: Formatters.dateTime(n.occurredAt, locale),
              child: Text(relativeTime(context, n.occurredAt), style: theme.textTheme.bodySmall),
            ),
            if (!n.isRead) StatusBadge(label: i18n.unread, tone: BadgeTone.info, icon: Icons.fiber_manual_record),
          ],
        ),
      ),
      onTap: () {
        context.read<NotificationsBloc>().add(NotificationOpened(n));
        if (n.isAboutAlert) {
          context.push('/alerts/${n.subjectId}');
        } else if (n.isAboutBatch) {
          context.push('/batches/${n.subjectId}');
        }
      },
    );
  }
}
