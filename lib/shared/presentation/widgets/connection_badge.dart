import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'status_badge.dart';

/// Connection of a device: [connected] is null when it is not known.
class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key, required this.connected});

  final bool? connected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (connected) {
      null => StatusBadge(label: l10n.telemetryUnavailable, tone: BadgeTone.neutral, icon: Icons.sensors_off_outlined),
      true => StatusBadge(label: l10n.connected, tone: BadgeTone.success, icon: Icons.wifi_rounded),
      false => StatusBadge(label: l10n.requiresReview, tone: BadgeTone.warning, icon: Icons.wifi_off_rounded),
    };
  }
}
