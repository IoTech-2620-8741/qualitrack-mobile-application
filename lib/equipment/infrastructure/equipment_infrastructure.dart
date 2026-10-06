import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/equipment.dart';

/// `EquipmentResource {id, laboratoryId, environmentId, name, type, model,
/// serialNumber, status, deviceType, sensorExternalId, firmwareVersion}`.
class EquipmentDto {
  const EquipmentDto(this.json);

  final Map<String, dynamic> json;

  Equipment toDomain() {
    final status = Json.optString(json, 'status');
    return Equipment(
      id: Json.requireInt(json, 'id'),
      laboratoryId: Json.requireInt(json, 'laboratoryId'),
      environmentId: Json.optInt(json, 'environmentId'),
      name: Json.requireString(json, 'name'),
      type: Json.optString(json, 'type'),
      model: Json.optString(json, 'model'),
      serialNumber: Json.optString(json, 'serialNumber'),
      status: EquipmentStatus.fromCode(status),
      rawStatus: status,
      deviceType: IotDeviceType.fromCode(Json.optString(json, 'deviceType')),
      sensorExternalId: Json.optString(json, 'sensorExternalId'),
      firmwareVersion: Json.optString(json, 'firmwareVersion'),
    );
  }
}

class MaintenanceRecordDto {
  const MaintenanceRecordDto(this.json);

  final Map<String, dynamic> json;

  MaintenanceRecord toDomain() => MaintenanceRecord(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    maintenanceDate: Json.optDateTime(json, 'maintenanceDate'),
    rawDate: Json.optString(json, 'maintenanceDate'),
    technicianName: Json.optString(json, 'technicianName'),
    description: Json.optString(json, 'description'),
    type: Json.optString(json, 'type'),
  );
}

class BpmParameterConfigDto {
  const BpmParameterConfigDto(this.json);

  final Map<String, dynamic> json;

  BpmParameterConfig toDomain() => BpmParameterConfig(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    parameterName: Json.requireString(json, 'parameterName'),
    minValue: Json.optDouble(json, 'minValue'),
    maxValue: Json.optDouble(json, 'maxValue'),
    unit: Json.optString(json, 'unit'),
  );
}

class EquipmentRemoteDataSource {
  const EquipmentRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<EquipmentDto>> getByLaboratory(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments')).map(EquipmentDto.new).toList();

  Future<EquipmentDto> getById(int labId, int id) async =>
      EquipmentDto(Json.asMap(await _client.get('/laboratories/$labId/equipments/$id')));

  Future<List<MaintenanceRecordDto>> getMaintenance(int labId, int environmentId, int id) async => Json.asList(
    await _client.get('/laboratories/$labId/environments/$environmentId/equipments/$id/maintenance-records'),
  ).map(MaintenanceRecordDto.new).toList();

  Future<List<BpmParameterConfigDto>> getBpmConfigs(int labId, int id) async => Json.asList(
    await _client.get('/laboratories/$labId/equipments/$id/bpm-configs'),
  ).map(BpmParameterConfigDto.new).toList();
}

class EquipmentRepositoryImpl implements EquipmentRepository {
  const EquipmentRepositoryImpl(this._remote);

  final EquipmentRemoteDataSource _remote;

  @override
  Future<List<Equipment>> getByLaboratory(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getByLaboratory(laboratoryId.value);
    // Same defensive filter as the Web DashboardStore.
    return dtos
        .map((dto) => dto.toDomain())
        .where((e) => e.laboratoryId == laboratoryId.value)
        .toList(growable: false);
  }

  @override
  Future<Equipment> getById(LaboratoryId laboratoryId, int equipmentId) async =>
      (await _remote.getById(laboratoryId.value, equipmentId)).toDomain();

  @override
  Future<List<MaintenanceRecord>> getMaintenance(
    LaboratoryId laboratoryId,
    int environmentId,
    int equipmentId,
  ) async => (await _remote.getMaintenance(laboratoryId.value, environmentId, equipmentId))
      .map((d) => d.toDomain())
      .toList(growable: false);

  @override
  Future<List<BpmParameterConfig>> getBpmConfigs(LaboratoryId laboratoryId, int equipmentId) async =>
      (await _remote.getBpmConfigs(laboratoryId.value, equipmentId))
          .map((d) => d.toDomain())
          .toList(growable: false);
}
