import 'package:flutter/widgets.dart';

import '../../batch/api/index.dart';
import '../../compliance/api/index.dart';
import '../../iam/api/index.dart';
import '../../tracking/api/index.dart' show MetricThreshold;
import '../../common/presentation/i18n/app_localizations.dart';

/// Widgets of other bounded contexts that the panel shows. The composition
/// root (`app/`) builds them, so this context never imports another context's
/// presentation.
class CommandCenterViews {
  const CommandCenterViews({
    required this.notificationBell,
    required this.profileButton,
    required this.roleLabel,
    required this.alertCard,
    required this.batchStatusBadge,
  });

  final Widget notificationBell;
  final Widget profileButton;

  final String Function(UserRole role, AppLocalizations i18n) roleLabel;
  /// An alert of the list; with [threshold], the range of its metric in its
  /// device's profile, it draws the value against the zones of that range.
  final Widget Function(
    DeviationAlert alert, {
    String? deviceName,
    String? environmentName,
    MetricThreshold? threshold,
    VoidCallback? onTap,
  })
  alertCard;
  final Widget Function(BatchStatus status) batchStatusBadge;
}
