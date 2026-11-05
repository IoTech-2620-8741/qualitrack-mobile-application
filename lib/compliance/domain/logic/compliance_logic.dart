import '../../../common/domain/failure.dart';
import '../entities/alert_severity.dart';
import '../entities/compliance_event.dart';
import '../entities/deviation_alert.dart';
import '../entities/notification_preferences.dart';

/// Business rules of Compliance & Alerting. Pure Dart: the facade applies them
/// on top of the repositories.
mixin ComplianceLogic {
  /// One entry per alert id, open critical alerts first (same order as Web).
  List<DeviationAlert> sortByPriority(List<DeviationAlert> alerts) {
    final byId = {for (final alert in alerts) alert.id: alert};
    return byId.values.toList()..sort(DeviationAlert.compareByPriority);
  }

  /// Resolving an alert requires resolution notes (backend rule).
  String requireResolutionNotes(String notes) {
    final text = notes.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'RESOLUTION_NOTES_REQUIRED');
    return text;
  }

  /// Newest event first; undated events go last, newest id first.
  List<ComplianceEvent> sortEventsNewestFirst(List<ComplianceEvent> events) => [...events]
    ..sort((a, b) {
      final left = a.timestamp;
      final right = b.timestamp;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });

  /// Only warning or critical can be chosen as the minimum severity, as in Web.
  NotificationPreferences requireValidPreferences(NotificationPreferences preferences) {
    if (preferences.minimumSeverity != AlertSeverity.warning &&
        preferences.minimumSeverity != AlertSeverity.critical) {
      throw const BadRequestFailure(code: 'INVALID_MINIMUM_SEVERITY');
    }
    return preferences;
  }
}
