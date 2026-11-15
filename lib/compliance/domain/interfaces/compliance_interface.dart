import '../../../common/domain/value_objects.dart';
import '../entities/app_notification.dart';
import '../entities/compliance_event.dart';
import '../entities/deviation_alert.dart';
import '../entities/notification_preferences.dart';

/// Contract of the compliance repository: what can be done with the deviation
/// alerts, the compliance events, the in-app notifications and the preferences
/// of the signed-in user, not how. Implemented by the infrastructure layer.
abstract interface class ComplianceInterface {
  Future<List<DeviationAlert>> getEnvironmentAlerts(LaboratoryId laboratoryId, int environmentId);
  Future<DeviationAlert> getAlert(int alertId);
  Future<DeviationAlert> acknowledge(int alertId);
  Future<DeviationAlert> resolve(int alertId, String resolutionNotes);
  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId);
  Future<List<ComplianceEvent>> getBatchEvents(int batchId);

  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50});
  Future<int> getUnreadCount();
  Future<void> markRead(int notificationId);
  Future<void> markAllRead();
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences);
}
