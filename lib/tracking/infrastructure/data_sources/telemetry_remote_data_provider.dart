import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/telemetry_target.dart';
import '../models/actuation_event_model.dart';
import '../models/device_connection_model.dart';
import '../models/environmental_profile_model.dart';
import '../models/measurement_model.dart';

/// Read-only access to Tracking. The acquisition endpoints (POST) are
/// intentionally not exposed: the mobile app never publishes telemetry.
class TelemetryRemoteDataProvider {
  const TelemetryRemoteDataProvider(this._client);

  final ApiClient _client;

  String _environment(int labId, int environmentId) => '/laboratories/$labId/environments/$environmentId';

  Future<DeviceConnectionModel> getConnection(int labId, int environmentId, int deviceId) async =>
      DeviceConnectionModel.fromJson(
        Json.asMap(await _client.get('${_environment(labId, environmentId)}/devices/$deviceId/telemetry-status')),
      );

  /// Environmental devices report per environment; container monitors per monitor.
  Future<List<MeasurementModel>> getMeasurements(
    int labId,
    TelemetryTarget target, {
    required String from,
    required String to,
  }) async {
    final base = _environment(labId, target.environmentId);
    final path = target.containerMonitor
        ? '$base/container-monitors/${target.deviceId}/telemetry-measurements'
        : '$base/telemetry-measurements';
    return Json.asList(await _client.get(path, query: {'from': from, 'to': to})).map(MeasurementModel.fromJson).toList();
  }

  Future<EnvironmentalProfileModel> getProfile(int labId, TelemetryTarget target) async =>
      EnvironmentalProfileModel.fromJson(
        Json.asMap(
          await _client.get(
            '${_environment(labId, target.environmentId)}/devices/${target.deviceId}/environmental-profile',
          ),
        ),
      );

  Future<List<ActuationEventModel>> getActuationEvents(
    int labId,
    TelemetryTarget target, {
    required String from,
    required String to,
  }) async => Json.asList(
    await _client.get(
      '${_environment(labId, target.environmentId)}/container-monitors/${target.deviceId}/actuation-events',
      query: {'from': from, 'to': to},
    ),
  ).map(ActuationEventModel.fromJson).toList();
}
