import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/inventory_material_model.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_receipt_model.dart';
import '../models/material_usage_model.dart';

/// Read-only access to the inventory endpoints of the QualiTrack REST API. Lot
/// registration, reviews, storage and consumptions remain in QualiTrack Web.
class InventoryRemoteDataProvider {
  const InventoryRemoteDataProvider(this._client);

  final ApiClient _client;

  String _materials(int labId, int environmentId) => '/laboratories/$labId/environments/$environmentId/raw-materials';

  Future<List<InventoryMaterialModel>> getMaterials(int labId, int environmentId) async =>
      Json.asList(await _client.get(_materials(labId, environmentId))).map(InventoryMaterialModel.fromJson).toList();

  Future<InventoryMaterialModel> getMaterial(int labId, int environmentId, int materialId) async =>
      InventoryMaterialModel.fromJson(Json.asMap(await _client.get('${_materials(labId, environmentId)}/$materialId')));

  Future<List<InventoryReceiptModel>> getReceipts(int labId, int environmentId, int materialId) async =>
      Json.asList(await _client.get('${_materials(labId, environmentId)}/$materialId/batches'))
          .map(InventoryReceiptModel.fromJson)
          .toList();

  Future<List<InventoryMovementModel>> getMovements(int labId, int environmentId, int materialId) async =>
      Json.asList(await _client.get('${_materials(labId, environmentId)}/$materialId/movements'))
          .map(InventoryMovementModel.fromJson)
          .toList();

  Future<List<MaterialUsageModel>> getUsages(int labId, int environmentId, int materialId) async =>
      Json.asList(await _client.get('${_materials(labId, environmentId)}/$materialId/usages'))
          .map(MaterialUsageModel.fromJson)
          .toList();
}
