import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/bpm_parameter_config_model.dart';
import '../models/equipment_model.dart';
import '../models/maintenance_record_model.dart';

/// Talks to the equipment endpoints of the QualiTrack REST API.
class EquipmentRemoteDataProvider {
  const EquipmentRemoteDataProvider(this._client);

  final ApiClient _client;

  Future<List<EquipmentModel>> getByLaboratory(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments')).map(EquipmentModel.fromJson).toList();

  Future<EquipmentModel> getById(int labId, int id) async =>
      EquipmentModel.fromJson(Json.asMap(await _client.get('/laboratories/$labId/equipments/$id')));

  Future<List<MaintenanceRecordModel>> getMaintenance(int labId, int environmentId, int id) async =>
      Json.asList(await _client.get('/laboratories/$labId/environments/$environmentId/equipments/$id/maintenance-records'))
          .map(MaintenanceRecordModel.fromJson)
          .toList();

  Future<List<BpmParameterConfigModel>> getBpmConfigs(int labId, int id) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments/$id/bpm-configs'))
          .map(BpmParameterConfigModel.fromJson)
          .toList();
}
