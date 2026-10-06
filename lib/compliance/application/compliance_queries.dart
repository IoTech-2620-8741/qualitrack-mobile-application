import '../../shared/application/bounded_concurrency.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/compliance.dart';

/// Alerts of every environment of the laboratory (the backend lists them
/// per environment), open critical alerts first.
class GetLaboratoryAlerts {
  const GetLaboratoryAlerts(this._repository);

  final ComplianceRepository _repository;

  Future<List<DeviationAlert>> call(LaboratoryId laboratoryId, Iterable<int> environmentIds) async {
    final alerts = await loadAll(
      environmentIds,
      (environmentId) => _repository.getEnvironmentAlerts(laboratoryId, environmentId),
    );
    final byId = {for (final alert in alerts) alert.id: alert};
    return byId.values.toList()..sort(DeviationAlert.compareByPriority);
  }
}

class GetAlertDetail {
  const GetAlertDetail(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call(int alertId) => _repository.getAlert(alertId);
}

/// Command: UNRESOLVED → ACKNOWLEDGED. The backend records the signed-in
/// user and the time.
class AcknowledgeAlert {
  const AcknowledgeAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call(int alertId) => _repository.acknowledge(alertId);
}

/// Command: → RESOLVED with mandatory resolution notes (backend rule).
class ResolveAlert {
  const ResolveAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call(int alertId, String resolutionNotes) {
    final notes = resolutionNotes.trim();
    if (notes.isEmpty) {
      throw const BadRequestFailure(code: 'RESOLUTION_NOTES_REQUIRED');
    }
    return _repository.resolve(alertId, notes);
  }
}

class GetEquipmentComplianceEvents {
  const GetEquipmentComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(LaboratoryId laboratoryId, int equipmentId) async =>
      _newestFirst(await _repository.getEquipmentEvents(laboratoryId, equipmentId));
}

class GetBatchComplianceEvents {
  const GetBatchComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(int batchId) async => _newestFirst(await _repository.getBatchEvents(batchId));
}

List<ComplianceEvent> _newestFirst(List<ComplianceEvent> events) => [...events]
  ..sort((a, b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });

/// Latest notifications of the signed-in user (the backend returns at most 100).
class GetNotifications {
  const GetNotifications(this._repository);

  final NotificationRepository _repository;

  Future<List<AppNotification>> call({int limit = 50}) => _repository.getNotifications(limit: limit);
}

class GetUnreadNotificationCount {
  const GetUnreadNotificationCount(this._repository);

  final NotificationRepository _repository;

  Future<int> call() => _repository.getUnreadCount();
}

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call(int notificationId) => _repository.markRead(notificationId);
}

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call() => _repository.markAllRead();
}

class GetNotificationPreferences {
  const GetNotificationPreferences(this._repository);

  final NotificationRepository _repository;

  Future<NotificationPreferences> call() => _repository.getPreferences();
}

/// Only warning or critical can be chosen as the minimum severity, as in Web.
class UpdateNotificationPreferences {
  const UpdateNotificationPreferences(this._repository);

  final NotificationRepository _repository;

  Future<NotificationPreferences> call(NotificationPreferences preferences) {
    if (preferences.minimumSeverity != AlertSeverity.warning &&
        preferences.minimumSeverity != AlertSeverity.critical) {
      throw const BadRequestFailure(code: 'INVALID_MINIMUM_SEVERITY');
    }
    return _repository.updatePreferences(preferences);
  }
}
