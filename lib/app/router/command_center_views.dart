import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../batch/presentation/widgets/batch_labels.dart';
import '../../command_center/presentation/command_center_views.dart';
import '../../compliance/presentation/bloc/unread_notifications_controller.dart';
import '../../compliance/presentation/widgets/alert_widgets.dart';
import '../../compliance/presentation/widgets/notification_bell.dart';
import '../../iam/domain/user_session.dart';
import '../../iam/presentation/widgets/role_labels.dart';
import '../../profile/presentation/bloc/current_profile_controller.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../common/presentation/i18n/app_localizations.dart';

/// Composition root of the panel: connects it with the widgets of the batch,
/// compliance, identity and profile contexts.
CommandCenterViews commandCenterViews({
  required UserSession session,
  required CurrentProfileController currentProfile,
  required UnreadNotificationsController notifications,
}) => CommandCenterViews(
  notificationBell: NotificationBell(controller: notifications),
  profileButton: ListenableBuilder(
    listenable: currentProfile,
    builder: (context, _) => IconButton(
      tooltip: context.l10n.profile,
      onPressed: () => context.push('/profile'),
      icon: ProfileAvatar(
        radius: 16,
        photo: currentProfile.photo,
        initials: currentProfile.profile?.initials ?? (session.username.isEmpty ? '?' : session.username[0].toUpperCase()),
      ),
    ),
  ),
  profileChanges: currentProfile,
  displayName: () => currentProfile.profile?.displayName,
  roleLabel: (role, l10n) => role.label(l10n),
  alertCard: (alert, {deviceName, environmentName, onTap}) =>
      AlertCard(alert: alert, deviceName: deviceName, environmentName: environmentName, onTap: onTap),
  batchStatusBadge: (status) => BatchStatusBadge(status: status),
);
