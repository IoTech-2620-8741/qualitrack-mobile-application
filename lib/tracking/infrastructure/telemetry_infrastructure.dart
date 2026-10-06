import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/telemetry.dart';

/// `DeviceTelemetryStatusResource {deviceId, connectionStatus, lastCommunicationAt, expectedPeriodSeconds}`.
class DeviceConnectionDto {
  const DeviceConnectionDto(this.json);

  final Map<String, dynamic> json;

  DeviceConnection toDomain() => DeviceConnection(
    deviceId: Json.requireInt(json, 'deviceId'),
    status: ConnectionStatus.fromCode(Json.optString(json, 'connectionStatus')),
    lastCommunicationAt: Json.optDateTime(json, 'lastCommunicationAt'),
    expectedPeriodSeconds: Json.optInt(json, 'expectedPeriodSeconds'),
  );
}

/// `MeasurementResource {id, deviceId, environmentId, metric, value, textValue,
/// unit, measuredAt, state, thresholdValue, profileVersion}`.
class MeasurementDto {
  const MeasurementDto(this.json);

  final Map<String, dynamic> json;

  Measurement toDomain() {
    final metric = Json.requireString(json, 'metric');
    return Measurement(
      id: Json.requireInt(json, 'id'),
      deviceId: Json.requireInt(json, 'deviceId'),
      environmentId: Json.requireInt(json, 'environmentId'),
      metric: MonitoredMetric.fromCode(metric),
      rawMetric: metric,
      value: Json.optDouble(json, 'value'),
      textValue: Json.optString(json, 'textValue'),
      unit: Json.optString(json, 'unit'),
      measuredAt: Json.optDateTime(json, 'measuredAt'),
      state: EnvironmentalState.fromCode(Json.optString(json, 'state')),
      thresholdValue: Json.optDouble(json, 'thresholdValue'),
      profileVersion: Json.optInt(json, 'profileVersion'),
    );
  }
}

/// `EnvironmentalProfileResource {version, thresholds[], actuationRules[], updatedAt}`.
class EnvironmentalProfileDto {
  const EnvironmentalProfileDto(this.json);

  final Map<String, dynamic> json;

  EnvironmentalProfile toDomain() => EnvironmentalProfile(
    version: Json.requireInt(json, 'version'),
    updatedAt: Json.optDateTime(json, 'updatedAt'),
    thresholds: [
      for (final item in _list('thresholds'))
        MetricThreshold(
          metric: MonitoredMetric.fromCode(Json.optString(item, 'metric')),
          unit: Json.optString(item, 'unit'),
          normalMin: Json.optDouble(item, 'normalMin'),
          normalMax: Json.optDouble(item, 'normalMax'),
          criticalMin: Json.optDouble(item, 'criticalMin'),
          criticalMax: Json.optDouble(item, 'criticalMax'),
        ),
    ],
    actuationRules: [
      for (final item in _list('actuationRules'))
        ActuationRule(
          metric: MonitoredMetric.fromCode(Json.optString(item, 'metric')),
          state: EnvironmentalState.fromCode(Json.optString(item, 'state')),
          action: Json.requireString(item, 'action'),
        ),
    ],
  );

  List<Map<String, dynamic>> _list(String key) => json[key] == null ? const [] : Json.asList(json[key]);
}

/// `ActuationEventResource {id, deviceId, action, triggerMetric, triggerState, result, occurredAt}`.
class ActuationEventDto {
  const ActuationEventDto(this.json);

  final Map<String, dynamic> json;

  ActuationEvent toDomain() {
    final metric = Json.optString(json, 'triggerMetric');
    final state = Json.optString(json, 'triggerState');
    return ActuationEvent(
      id: Json.requireInt(json, 'id'),
      deviceId: Json.requireInt(json, 'deviceId'),
      action: Json.requireString(json, 'action'),
      result: Json.requireString(json, 'result'),
      triggerMetric: metric == null ? null : MonitoredMetric.fromCode(metric),
      triggerState: state == null ? null : EnvironmentalState.fromCode(state),
      occurredAt: Json.optDateTime(json, 'occurredAt'),
    );
  }
}

/// Read-only access to Tracking. The acquisition endpoints (POST) are
/// intentionally not exposed: the mobile app never publishes telemetry.
class TelemetryRemoteDataSource {
  const TelemetryRemoteDataSource(this._client);

  final ApiClient _client;

  String _environment(int labId, int environmentId) => '/laboratories/$labId/environments/$environmentId';

  Future<DeviceConnectionDto> getConnection(int labId, int environmentId, int deviceId) async =>
      DeviceConnectionDto(Json.asMap(
        await _client.get('${_environment(labId, environmentId)}/devices/$deviceId/telemetry-status'),
      ));

  /// Environmental devices report per environment; container monitors per monitor.
  Future<List<MeasurementDto>> getMeasurements(
    int labId,
    TelemetryTarget target, {
    required String from,
    required String to,
  }) async {
    final base = _environment(labId, target.environmentId);
    final path = target.containerMonitor
        ? '$base/container-monitors/${target.deviceId}/telemetry-measurements'
        : '$base/telemetry-measurements';
    return Json.asList(await _client.get(path, query: {'from': from, 'to': to})).map(MeasurementDto.new).toList();
  }

  Future<EnvironmentalProfileDto> getProfile(int labId, TelemetryTarget target) async => EnvironmentalProfileDto(
    Json.asMap(await _client.get(
      '${_environment(labId, target.environmentId)}/devices/${target.deviceId}/environmental-profile',
    )),
  );

  Future<List<ActuationEventDto>> getActuationEvents(
    int labId,
    TelemetryTarget target, {
    required String from,
    required String to,
  }) async => Json.asList(
    await _client.get(
      '${_environment(labId, target.environmentId)}/container-monitors/${target.deviceId}/actuation-events',
      query: {'from': from, 'to': to},
    ),
  ).map(ActuationEventDto.new).toList();
}

class TelemetryRepositoryImpl implements TelemetryRepository {
  const TelemetryRepositoryImpl(this._remote);

  final TelemetryRemoteDataSource _remote;

  @override
  Future<DeviceConnection> getConnection(LaboratoryId laboratoryId, TelemetryTarget target) async =>
      (await _remote.getConnection(laboratoryId.value, target.environmentId, target.deviceId)).toDomain();

  /// Same wire format as Web: `Date.toISOString()` (UTC, milliseconds, `Z`).
  @override
  Future<List<Measurement>> getMeasurements(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async => (await _remote.getMeasurements(
    laboratoryId.value,
    target,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
  )).map((d) => d.toDomain()).toList(growable: false);

  @override
  Future<EnvironmentalProfile?> getProfile(LaboratoryId laboratoryId, TelemetryTarget target) =>
      nullOnNotFound(() async => (await _remote.getProfile(laboratoryId.value, target)).toDomain());

  @override
  Future<List<ActuationEvent>> getActuationEvents(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async => (await _remote.getActuationEvents(
    laboratoryId.value,
    target,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
  )).map((d) => d.toDomain()).toList(growable: false);
}
