import 'package:equatable/equatable.dart';

import 'alert_severity.dart';

/// How the signed-in user wants to be notified about alerts. Batch notices
/// ignore the minimum severity.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.minimumSeverity,
  });

  final bool inAppEnabled;
  final bool emailEnabled;
  final AlertSeverity minimumSeverity;

  NotificationPreferences copyWith({bool? inAppEnabled, bool? emailEnabled, AlertSeverity? minimumSeverity}) =>
      NotificationPreferences(
        inAppEnabled: inAppEnabled ?? this.inAppEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
        minimumSeverity: minimumSeverity ?? this.minimumSeverity,
      );

  @override
  List<Object?> get props => [inAppEnabled, emailEnabled, minimumSeverity];
}
