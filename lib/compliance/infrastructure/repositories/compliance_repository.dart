import '../../../common/domain/value_objects.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/compliance_event.dart';
import '../../domain/entities/deviation_alert.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/interfaces/compliance_interface.dart';
import '../data_sources/compliance_remote_data_provider.dart';

/// Implements [ComplianceInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider.
class ComplianceRepository implements ComplianceInterface {
  const ComplianceRepository({required ComplianceRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final ComplianceRemoteDataProvider _remote;

  @override
  Future<List<DeviationAlert>> getEnvironmentAlerts(LaboratoryId laboratoryId, int environmentId) =>
      _remote.getEnvironmentAlerts(laboratoryId.value, environmentId);

  @override
  Future<DeviationAlert> getAlert(int alertId) => _remote.getAlert(alertId);

  @override
  Future<DeviationAlert> acknowledge(int alertId) => _remote.acknowledge(alertId);

  @override
  Future<DeviationAlert> resolve(int alertId, String resolutionNotes) => _remote.resolve(alertId, resolutionNotes);

  @override
  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId) =>
      _remote.getEquipmentEvents(laboratoryId.value, equipmentId);

  @override
  Future<List<ComplianceEvent>> getBatchEvents(int batchId) => _remote.getBatchEvents(batchId);

  @override
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50}) =>
      _remote.getNotifications(unreadOnly: unreadOnly, limit: limit);

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markRead(int notificationId) => _remote.markRead(notificationId);

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<NotificationPreferences> getPreferences() => _remote.getPreferences();

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) =>
      _remote.updatePreferences(preferences);
}
