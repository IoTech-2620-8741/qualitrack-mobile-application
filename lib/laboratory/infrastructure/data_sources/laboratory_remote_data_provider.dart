import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/lab_environment_model.dart';
import '../models/laboratory_model.dart';
import '../models/pharmaceutical_product_model.dart';
import '../models/staff_member_model.dart';

/// Talks to the laboratory endpoints of the QualiTrack REST API.
class LaboratoryRemoteDataProvider {
  const LaboratoryRemoteDataProvider(this._client);

  final ApiClient _client;

  Future<LaboratoryModel> getLaboratory(int id) async =>
      LaboratoryModel.fromJson(Json.asMap(await _client.get('/laboratories/$id')));

  Future<List<LabEnvironmentModel>> getEnvironments(int id) async =>
      Json.asList(await _client.get('/laboratories/$id/environments')).map(LabEnvironmentModel.fromJson).toList();

  Future<List<PharmaceuticalProductModel>> getProducts(int id, int environmentId) async =>
      Json.asList(await _client.get('/laboratories/$id/environments/$environmentId/products'))
          .map(PharmaceuticalProductModel.fromJson)
          .toList();

  Future<List<StaffMemberModel>> getStaff(int id) async =>
      Json.asList(await _client.get('/laboratories/$id/staff')).map(StaffMemberModel.fromJson).toList();
}
