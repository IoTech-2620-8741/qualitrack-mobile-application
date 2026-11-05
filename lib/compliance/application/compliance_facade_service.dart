import '../../common/application/bounded_concurrency.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/app_notification.dart';
import '../domain/entities/compliance_event.dart';
import '../domain/entities/deviation_alert.dart';
import '../domain/entities/notification_preferences.dart';
import '../domain/interfaces/compliance_interface.dart';
import '../domain/interfaces/notification_interface.dart';
import '../domain/logic/compliance_logic.dart';

/// Use cases of Compliance & Alerting exposed to the presentation layer. It
/// only orchestrates: the rules live in [ComplianceLogic] and the data access
/// behind [ComplianceInterface] and [NotificationInterface].
class ComplianceFacadeService with ComplianceLogic {
  const ComplianceFacadeService({
    required ComplianceInterface complianceRepository,
    required NotificationInterface notificationRepository,
  }) : _alerts = complianceRepository,
       _notifications = notificationRepository;

  final ComplianceInterface _alerts;
  final NotificationInterface _notifications;

  /// Alerts of every environment of the laboratory (the backend lists them per
  /// environment), open critical alerts first.
  Future<List<DeviationAlert>> getLaboratoryAlerts(LaboratoryId laboratoryId, Iterable<int> environmentIds) async =>
      sortByPriority(
        await loadAll(environmentIds, (environmentId) => _alerts.getEnvironmentAlerts(laboratoryId, environmentId)),
      );

  Future<DeviationAlert> getAlert(int alertId) => _alerts.getAlert(alertId);

  /// Command: UNRESOLVED → ACKNOWLEDGED. The backend records the signed-in
  /// user and the time.
  Future<DeviationAlert> acknowledgeAlert(int alertId) => _alerts.acknowledge(alertId);

  /// Command: → RESOLVED with mandatory resolution notes.
  Future<DeviationAlert> resolveAlert(int alertId, String resolutionNotes) =>
      _alerts.resolve(alertId, requireResolutionNotes(resolutionNotes));

  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId) async =>
      sortEventsNewestFirst(await _alerts.getEquipmentEvents(laboratoryId, equipmentId));

  Future<List<ComplianceEvent>> getBatchEvents(int batchId) async =>
      sortEventsNewestFirst(await _alerts.getBatchEvents(batchId));

  /// Latest notifications of the signed-in user (the backend returns at most 100).
  Future<List<AppNotification>> getNotifications({int limit = 50}) => _notifications.getNotifications(limit: limit);

  Future<int> getUnreadCount() => _notifications.getUnreadCount();

  Future<void> markNotificationRead(int notificationId) => _notifications.markRead(notificationId);

  Future<void> markAllNotificationsRead() => _notifications.markAllRead();

  Future<NotificationPreferences> getPreferences() => _notifications.getPreferences();

  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) =>
      _notifications.updatePreferences(requireValidPreferences(preferences));
}
