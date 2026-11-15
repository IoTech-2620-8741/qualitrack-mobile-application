import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/notification_preferences.dart';
import '../models/app_notification_model.dart';
import '../models/compliance_event_model.dart';
import '../models/deviation_alert_model.dart';
import '../models/notification_preferences_model.dart';

/// Talks to the alerts, compliance events and notifications endpoints of the
/// QualiTrack REST API.
class ComplianceRemoteDataProvider {
  const ComplianceRemoteDataProvider(this._client);

  final ApiClient _client;

  Future<List<DeviationAlertModel>> getEnvironmentAlerts(int labId, int environmentId) async =>
      Json.asList(await _client.get('/laboratories/$labId/environments/$environmentId/deviation-alerts'))
          .map(DeviationAlertModel.fromJson)
          .toList();

  Future<DeviationAlertModel> getAlert(int alertId) async =>
      DeviationAlertModel.fromJson(Json.asMap(await _client.get('/deviation-alerts/$alertId')));

  Future<DeviationAlertModel> acknowledge(int alertId) async =>
      DeviationAlertModel.fromJson(Json.asMap(await _client.post('/deviation-alerts/$alertId/acknowledgements')));

  Future<DeviationAlertModel> resolve(int alertId, String notes) async => DeviationAlertModel.fromJson(
    Json.asMap(await _client.post('/deviation-alerts/$alertId/resolutions', body: {'resolutionNotes': notes})),
  );

  Future<List<ComplianceEventModel>> getEquipmentEvents(int labId, int equipmentId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments/$equipmentId/compliance-events'))
          .map(ComplianceEventModel.fromJson)
          .toList();

  Future<List<ComplianceEventModel>> getBatchEvents(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/compliance-events')).map(ComplianceEventModel.fromJson).toList();

  Future<List<AppNotificationModel>> getNotifications({required bool unreadOnly, required int limit}) async =>
      Json.asList(
        await _client.get('/users/me/notifications', query: {'unread': unreadOnly ? true : null, 'limit': limit}),
      ).map(AppNotificationModel.fromJson).toList();

  Future<int> getUnreadCount() async =>
      Json.requireInt(Json.asMap(await _client.get('/users/me/notifications/unread-count')), 'unreadCount');

  Future<void> markRead(int notificationId) => _client.post('/users/me/notifications/$notificationId/read-receipts');

  Future<void> markAllRead() => _client.post('/users/me/notifications/read-receipts');

  Future<NotificationPreferencesModel> getPreferences() async =>
      NotificationPreferencesModel.fromJson(Json.asMap(await _client.get('/users/me/notification-preferences')));

  Future<NotificationPreferencesModel> updatePreferences(NotificationPreferences preferences) async =>
      NotificationPreferencesModel.fromJson(
        Json.asMap(
          await _client.put('/users/me/notification-preferences', body: NotificationPreferencesModel.body(preferences)),
        ),
      );
}
