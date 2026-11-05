import 'package:flutter/widgets.dart';

import '../../batch/api/index.dart';
import '../../compliance/api/index.dart';
import '../../iam/api/index.dart';
import '../../shared/presentation/l10n/app_localizations.dart';

/// Widgets of other bounded contexts that the panel shows. The composition
/// root (`app/`) builds them, so this context never imports another context's
/// presentation.
class CommandCenterViews {
  const CommandCenterViews({
    required this.notificationBell,
    required this.profileButton,
    required this.profileChanges,
    required this.displayName,
    required this.roleLabel,
    required this.alertCard,
    required this.batchStatusBadge,
  });

  final Widget notificationBell;
  final Widget profileButton;

  /// Notifies when [displayName] may have changed.
  final Listenable profileChanges;
  final String? Function() displayName;
  final String Function(UserRole role, AppLocalizations l10n) roleLabel;
  final Widget Function(DeviationAlert alert, {String? deviceName, String? environmentName, VoidCallback? onTap})
  alertCard;
  final Widget Function(BatchStatus status) batchStatusBadge;
}
