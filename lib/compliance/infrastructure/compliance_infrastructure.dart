import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/compliance.dart';

class DeviationAlertDto {
  const DeviationAlertDto(this.json);

  final Map<String, dynamic> json;

  DeviationAlert toDomain() => DeviationAlert(
    id: Json.requireInt(json, 'id'),
    environmentId: Json.optInt(json, 'environmentId'),
    origin: AlertOrigin.fromCode(Json.optString(json, 'origin')),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    batchId: Json.optInt(json, 'batchId'),
    parameterName: Json.requireString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    thresholdValue: Json.optDouble(json, 'thresholdValue'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    status: AlertStatus.fromCode(Json.optString(json, 'status')),
    deviationCount: Json.optInt(json, 'deviationCount') ?? 1,
    lastDetectedAt: Json.optDateTime(json, 'lastDetectedAt'),
    normalizedAt: Json.optDateTime(json, 'normalizedAt'),
    acknowledgedBy: Json.optInt(json, 'acknowledgedBy'),
    acknowledgedAt: Json.optDateTime(json, 'acknowledgedAt'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
    resolvedAt: Json.optDateTime(json, 'resolvedAt'),
    resolutionNotes: Json.optString(json, 'resolutionNotes'),
    relatedActuations: [
      if (json['relatedActuations'] != null)
        for (final item in Json.asList(json['relatedActuations']))
          RelatedActuation(
            id: Json.requireInt(item, 'id'),
            action: Json.requireString(item, 'action'),
            result: Json.requireString(item, 'result'),
            triggerState: Json.optString(item, 'triggerState'),
            occurredAt: Json.optDateTime(item, 'occurredAt'),
          ),
    ],
  );
}

class ComplianceEventDto {
  const ComplianceEventDto(this.json);

  final Map<String, dynamic> json;

  ComplianceEvent toDomain() => ComplianceEvent(
    id: Json.requireInt(json, 'id'),
    eventType: Json.requireString(json, 'eventType'),
    relatedEntityId: Json.optInt(json, 'relatedEntityId'),
    description: Json.optString(json, 'description'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
  );
}

/// `NotificationResource`.
class NotificationDto {
  const NotificationDto(this.json);

  final Map<String, dynamic> json;

  AppNotification toDomain() => AppNotification(
    id: Json.requireInt(json, 'id'),
    type: NotificationType.fromCode(Json.optString(json, 'type')),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    subjectType: Json.requireString(json, 'subjectType'),
    subjectId: Json.requireInt(json, 'subjectId'),
    environmentName: Json.optString(json, 'environmentName'),
    subjectName: Json.optString(json, 'subjectName'),
    parameterName: Json.optString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    unit: Json.optString(json, 'unit'),
    actorName: Json.optString(json, 'actorName'),
    note: Json.optString(json, 'note'),
    occurredAt: Json.optDateTime(json, 'occurredAt'),
    readAt: Json.optDateTime(json, 'readAt'),
  );
}

/// `NotificationPreferenceResource {emailEnabled, inAppEnabled, minimumSeverity}`.
class NotificationPreferencesDto {
  const NotificationPreferencesDto(this.json);

  final Map<String, dynamic> json;

  NotificationPreferences toDomain() => NotificationPreferences(
    inAppEnabled: Json.optBool(json, 'inAppEnabled') ?? true,
    emailEnabled: Json.optBool(json, 'emailEnabled') ?? false,
    minimumSeverity: AlertSeverity.fromCode(Json.optString(json, 'minimumSeverity')),
  );

  static Map<String, dynamic> body(NotificationPreferences preferences) => {
    'inAppEnabled': preferences.inAppEnabled,
    'emailEnabled': preferences.emailEnabled,
    'minimumSeverity': preferences.minimumSeverity.code,
  };
}

class ComplianceRemoteDataSource {
  const ComplianceRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<DeviationAlertDto>> getEnvironmentAlerts(int labId, int environmentId) async => Json.asList(
    await _client.get('/laboratories/$labId/environments/$environmentId/deviation-alerts'),
  ).map(DeviationAlertDto.new).toList();

  Future<DeviationAlertDto> getAlert(int alertId) async =>
      DeviationAlertDto(Json.asMap(await _client.get('/deviation-alerts/$alertId')));

  Future<DeviationAlertDto> acknowledge(int alertId) async =>
      DeviationAlertDto(Json.asMap(await _client.post('/deviation-alerts/$alertId/acknowledgements')));

  Future<DeviationAlertDto> resolve(int alertId, String notes) async => DeviationAlertDto(Json.asMap(
    await _client.post('/deviation-alerts/$alertId/resolutions', body: {'resolutionNotes': notes}),
  ));

  Future<List<ComplianceEventDto>> getEquipmentEvents(int labId, int equipmentId) async => Json.asList(
    await _client.get('/laboratories/$labId/equipments/$equipmentId/compliance-events'),
  ).map(ComplianceEventDto.new).toList();

  Future<List<ComplianceEventDto>> getBatchEvents(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/compliance-events')).map(ComplianceEventDto.new).toList();

  Future<List<NotificationDto>> getNotifications({required bool unreadOnly, required int limit}) async =>
      Json.asList(await _client.get(
        '/users/me/notifications',
        query: {'unread': unreadOnly ? true : null, 'limit': limit},
      )).map(NotificationDto.new).toList();

  Future<int> getUnreadCount() async =>
      Json.requireInt(Json.asMap(await _client.get('/users/me/notifications/unread-count')), 'unreadCount');

  Future<void> markRead(int notificationId) =>
      _client.post('/users/me/notifications/$notificationId/read-receipts');

  Future<void> markAllRead() => _client.post('/users/me/notifications/read-receipts');

  Future<NotificationPreferencesDto> getPreferences() async =>
      NotificationPreferencesDto(Json.asMap(await _client.get('/users/me/notification-preferences')));

  Future<NotificationPreferencesDto> updatePreferences(NotificationPreferences preferences) async =>
      NotificationPreferencesDto(Json.asMap(await _client.put(
        '/users/me/notification-preferences',
        body: NotificationPreferencesDto.body(preferences),
      )));
}

class ComplianceRepositoryImpl implements ComplianceRepository {
  const ComplianceRepositoryImpl(this._remote);

  final ComplianceRemoteDataSource _remote;

  @override
  Future<List<DeviationAlert>> getEnvironmentAlerts(LaboratoryId laboratoryId, int environmentId) async =>
      (await _remote.getEnvironmentAlerts(laboratoryId.value, environmentId))
          .map((d) => d.toDomain())
          .toList(growable: false);

  @override
  Future<DeviationAlert> getAlert(int alertId) async => (await _remote.getAlert(alertId)).toDomain();

  @override
  Future<DeviationAlert> acknowledge(int alertId) async => (await _remote.acknowledge(alertId)).toDomain();

  @override
  Future<DeviationAlert> resolve(int alertId, String resolutionNotes) async =>
      (await _remote.resolve(alertId, resolutionNotes)).toDomain();

  @override
  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId) async =>
      (await _remote.getEquipmentEvents(laboratoryId.value, equipmentId))
          .map((d) => d.toDomain())
          .toList(growable: false);

  @override
  Future<List<ComplianceEvent>> getBatchEvents(int batchId) async =>
      (await _remote.getBatchEvents(batchId)).map((d) => d.toDomain()).toList(growable: false);
}

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final ComplianceRemoteDataSource _remote;

  @override
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50}) async =>
      (await _remote.getNotifications(unreadOnly: unreadOnly, limit: limit))
          .map((d) => d.toDomain())
          .toList(growable: false);

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markRead(int notificationId) => _remote.markRead(notificationId);

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<NotificationPreferences> getPreferences() async => (await _remote.getPreferences()).toDomain();

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async =>
      (await _remote.updatePreferences(preferences)).toDomain();
}
