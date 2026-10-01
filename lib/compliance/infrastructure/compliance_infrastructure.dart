import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/compliance.dart';

class DeviationAlertDto {
  const DeviationAlertDto(this.json);

  final Map<String, dynamic> json;

  DeviationAlert toDomain() => DeviationAlert(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    batchId: Json.optInt(json, 'batchId'),
    parameterName: Json.requireString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    thresholdValue: Json.optDouble(json, 'thresholdValue'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    status: AlertStatus.fromCode(Json.optString(json, 'status')),
    acknowledgedBy: Json.optInt(json, 'acknowledgedBy'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
    resolutionNotes: Json.optString(json, 'resolutionNotes'),
  );
}

/// Body of `PATCH /deviation-alerts/{id}` (`UpdateDeviationAlertStatusResource`).
class UpdateAlertStatusRequest {
  const UpdateAlertStatusRequest({
    required this.status,
    required this.performedBy,
    this.resolutionNotes,
  });

  final AlertStatus status;
  final int performedBy;
  final String? resolutionNotes;

  Map<String, dynamic> toJson() => {
    'status': status.code,
    'performedBy': performedBy,
    'resolutionNotes': resolutionNotes,
  };
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

class ComplianceRemoteDataSource {
  const ComplianceRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<DeviationAlertDto>> getEquipmentAlerts(int equipmentId) async => Json.asList(
    await _client.get('/equipments/$equipmentId/deviation-alerts'),
  ).map(DeviationAlertDto.new).toList();

  Future<List<DeviationAlertDto>> getBatchAlerts(int batchId) async => Json.asList(
    await _client.get('/batches/$batchId/deviation-alerts'),
  ).map(DeviationAlertDto.new).toList();

  Future<DeviationAlertDto> getAlert(int alertId) async =>
      DeviationAlertDto(Json.asMap(await _client.get('/deviation-alerts/$alertId')));

  Future<DeviationAlertDto> updateStatus(int alertId, UpdateAlertStatusRequest request) async =>
      DeviationAlertDto(
        Json.asMap(await _client.patch('/deviation-alerts/$alertId', body: request.toJson())),
      );

  Future<List<ComplianceEventDto>> getEquipmentEvents(int equipmentId) async => Json.asList(
    await _client.get('/equipments/$equipmentId/compliance-events'),
  ).map(ComplianceEventDto.new).toList();

  Future<List<ComplianceEventDto>> getBatchEvents(int batchId) async => Json.asList(
    await _client.get('/batches/$batchId/compliance-events'),
  ).map(ComplianceEventDto.new).toList();
}

class ComplianceRepositoryImpl implements ComplianceRepository {
  const ComplianceRepositoryImpl(this._remote);

  final ComplianceRemoteDataSource _remote;

  @override
  Future<List<DeviationAlert>> getEquipmentAlerts(int equipmentId) async =>
      (await _remote.getEquipmentAlerts(equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<DeviationAlert>> getBatchAlerts(int batchId) async =>
      (await _remote.getBatchAlerts(batchId)).map((d) => d.toDomain()).toList();

  @override
  Future<DeviationAlert> getAlert(int alertId) async => (await _remote.getAlert(alertId)).toDomain();

  @override
  Future<DeviationAlert> acknowledge({required int alertId, required int performedBy}) async {
    final dto = await _remote.updateStatus(
      alertId,
      UpdateAlertStatusRequest(status: AlertStatus.acknowledged, performedBy: performedBy),
    );
    return dto.toDomain();
  }

  @override
  Future<DeviationAlert> resolve({
    required int alertId,
    required int performedBy,
    required String resolutionNotes,
  }) async {
    final dto = await _remote.updateStatus(
      alertId,
      UpdateAlertStatusRequest(
        status: AlertStatus.resolved,
        performedBy: performedBy,
        resolutionNotes: resolutionNotes,
      ),
    );
    return dto.toDomain();
  }

  @override
  Future<List<ComplianceEvent>> getEquipmentEvents(int equipmentId) async =>
      (await _remote.getEquipmentEvents(equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<ComplianceEvent>> getBatchEvents(int batchId) async =>
      (await _remote.getBatchEvents(batchId)).map((d) => d.toDomain()).toList();
}
