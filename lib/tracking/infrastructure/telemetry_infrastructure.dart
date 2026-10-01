import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/telemetry.dart';

class TelemetryStatusDto {
  const TelemetryStatusDto(this.json);

  final Map<String, dynamic> json;

  EquipmentTelemetryStatus toDomain() => EquipmentTelemetryStatus(
    id: Json.optInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    isOnline: Json.optBool(json, 'isOnline') ?? false,
    currentStatus: TelemetryStatus.fromCode(Json.optString(json, 'currentStatus')),
    lastHeartbeat: Json.optDateTime(json, 'lastHeartbeat'),
    rawLastHeartbeat: Json.optString(json, 'lastHeartbeat'),
  );
}

class MeasurementDto {
  const MeasurementDto(this.json);

  final Map<String, dynamic> json;

  Measurement toDomain() => Measurement(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    parameterName: Json.requireString(json, 'parameterName'),
    value: Json.requireDouble(json, 'value'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
  );
}

class TelemetryHistoryPointDto {
  const TelemetryHistoryPointDto(this.json);

  final Map<String, dynamic> json;

  TelemetryHistoryPoint toDomain() => TelemetryHistoryPoint(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    parameterName: Json.requireString(json, 'parameterName'),
    recordedValue: Json.requireDouble(json, 'recordedValue'),
    isAnomaly: Json.optBool(json, 'isAnomaly') ?? false,
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
  );
}

/// Read-only access to Tracking. The POST/PUT acquisition endpoints are
/// intentionally not exposed: the mobile app never publishes telemetry.
class TelemetryRemoteDataSource {
  const TelemetryRemoteDataSource(this._client);

  final ApiClient _client;

  Future<TelemetryStatusDto> getStatus(int equipmentId) async => TelemetryStatusDto(
    Json.asMap(await _client.get('/equipments/$equipmentId/telemetry-status')),
  );

  Future<List<MeasurementDto>> getMeasurements(int equipmentId) async => Json.asList(
    await _client.get('/equipments/$equipmentId/telemetry-measurements'),
  ).map(MeasurementDto.new).toList();

  Future<List<TelemetryHistoryPointDto>> getHistory(
    int equipmentId, {
    String? from,
    String? to,
  }) async => Json.asList(
    await _client.get(
      '/equipments/$equipmentId/telemetry-history',
      query: {'from': from, 'to': to},
    ),
  ).map(TelemetryHistoryPointDto.new).toList();
}

class TelemetryRepositoryImpl implements TelemetryRepository {
  const TelemetryRepositoryImpl(this._remote);

  final TelemetryRemoteDataSource _remote;

  @override
  Future<EquipmentTelemetryStatus> getStatus(int equipmentId) async =>
      (await _remote.getStatus(equipmentId)).toDomain();

  @override
  Future<List<Measurement>> getLatestMeasurements(int equipmentId) async =>
      (await _remote.getMeasurements(equipmentId)).map((d) => d.toDomain()).toList(growable: false);

  /// Same wire format as Web: `Date.toISOString()` (UTC, milliseconds, `Z`).
  @override
  Future<List<TelemetryHistoryPoint>> getHistory(
    int equipmentId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final dtos = await _remote.getHistory(
      equipmentId,
      from: from == null ? null : toIsoMillis(from),
      to: to == null ? null : toIsoMillis(to),
    );
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }
}

/// `2026-06-14T15:50:00.000Z`, identical to JavaScript `Date.toISOString()`.
String toIsoMillis(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
  value.millisecondsSinceEpoch,
  isUtc: true,
).toIso8601String();
