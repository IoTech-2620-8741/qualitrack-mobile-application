import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/l10n/app_localizations.dart';
import '../bloc/unread_notifications_controller.dart';

/// Bell of the app bars with the unread count, as in the Web toolbar.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.controller});

  final UnreadNotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.count;
        return IconButton(
          tooltip: count == 0 ? l10n.notificationsTitle : l10n.notificationsUnread(count),
          onPressed: () async {
            await context.push('/notifications');
            await controller.refresh();
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
