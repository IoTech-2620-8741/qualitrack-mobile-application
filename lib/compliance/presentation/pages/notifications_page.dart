import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/compliance.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/alert_widgets.dart';

/// In-app notices (US: receive notices in the app). Opening one marks it as
/// read and leads to the alert or the batch.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<NotificationsBloc>();
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.actionFailure != b.actionFailure && b.actionFailure != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.critical,
        content: Text(failureMessage(context, state.actionFailure!)),
      )),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.notificationsTitle),
          actions: [
            IconButton(
              tooltip: l10n.markAllRead,
              onPressed: state.unread == 0 ? null : () => bloc.add(const NotificationsAllRead()),
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              tooltip: l10n.notificationPreferences,
              onPressed: () => context.push('/profile/notifications'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: RemoteStateView<List<AppNotification>>(
          state: state.remote,
          onRetry: () => bloc.add(const NotificationsRequested()),
          emptyIcon: Icons.notifications_none,
          emptyMessage: l10n.notificationsEmpty,
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
String notificationText(AppLocalizations l10n, AppNotification n, String locale) {
  final environment = n.environmentName ?? l10n.anEnvironment;
  final variable = alertVariable(l10n, n.parameterName ?? '');
  final value = n.recordedValue == null ? '—' : Formatters.number(n.recordedValue, locale);
  final unit = n.unit ?? '';
  final actor = n.actorName ?? l10n.someone;
  final text = switch (n.type) {
    NotificationType.alertOpened => l10n.noticeAlertOpened(_severityWord(l10n, n.severity), environment, variable, value, unit),
    NotificationType.alertEscalated => l10n.noticeAlertEscalated(variable, environment, _levelWord(l10n, n.severity), value, unit),
    NotificationType.alertAcknowledged => l10n.noticeAlertAcknowledged(actor, variable, environment),
    NotificationType.alertResolved => l10n.noticeAlertResolved(actor, variable, environment),
    NotificationType.batchReleased => l10n.noticeBatchReleased(actor, n.subjectName ?? '#${n.subjectId}'),
    NotificationType.batchRejected => l10n.noticeBatchRejected(actor, n.subjectName ?? '#${n.subjectId}', n.note ?? ''),
    NotificationType.unknown => n.note ?? n.subjectName ?? '',
  };
  return text.replaceAll(RegExp(r'\s+\.'), '.').trim();
}

/// "critical" in "New critical alert in …".
String _severityWord(AppLocalizations l10n, AlertSeverity severity) => switch (severity) {
  AlertSeverity.low => l10n.noticeSeverityLow,
  AlertSeverity.critical => l10n.noticeSeverityCritical,
  _ => l10n.noticeSeverityWarning,
};

/// "critical" in "… rose to critical".
String _levelWord(AppLocalizations l10n, AlertSeverity severity) => switch (severity) {
  AlertSeverity.low => l10n.noticeLevelLow,
  AlertSeverity.critical => l10n.noticeLevelCritical,
  _ => l10n.noticeLevelWarning,
};

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon => switch (notification.type) {
    NotificationType.alertOpened || NotificationType.alertEscalated => Icons.warning_amber_rounded,
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
    final l10n = context.l10n;
    final locale = context.localeName;
    final n = notification;
    final theme = Theme.of(context);
    return Material(
      color: n.isRead ? null : AppColors.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.12),
          child: Icon(_icon, color: _color),
        ),
        title: Text(
          notificationText(l10n, n, locale),
          style: n.isRead ? theme.textTheme.bodyMedium : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(Formatters.dateTime(n.occurredAt, locale), style: theme.textTheme.bodySmall),
              if (!n.isRead) StatusBadge(label: l10n.unread, tone: BadgeTone.brand),
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
      ),
    );
  }
}
