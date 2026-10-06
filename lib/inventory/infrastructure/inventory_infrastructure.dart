import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/inventory.dart';

class InventoryMaterialDto {
  const InventoryMaterialDto(this.json);

  final Map<String, dynamic> json;

  InventoryMaterial toDomain() => InventoryMaterial(
    id: Json.requireInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    environmentId: Json.requireInt(json, 'environmentId'),
    code: Json.optString(json, 'code') ?? '',
    name: Json.requireString(json, 'name'),
    unit: Json.optString(json, 'unit') ?? '',
    minimumStock: Json.optDouble(json, 'minimumStock') ?? 0,
    usableStock: Json.optDouble(json, 'usableStock') ?? 0,
    physicalStock: Json.optDouble(json, 'physicalStock') ?? 0,
    stockStatus: Json.optString(json, 'stockStatus'),
    legacyId: Json.optInt(json, 'legacyId'),
  );
}

class InventoryReceiptDto {
  const InventoryReceiptDto(this.json);

  final Map<String, dynamic> json;

  InventoryReceipt toDomain() => InventoryReceipt(
    id: Json.requireInt(json, 'id'),
    rawMaterialId: Json.requireInt(json, 'rawMaterialId'),
    supplier: Json.optString(json, 'supplier'),
    batchNumber: Json.optString(json, 'batchNumber'),
    unit: Json.optString(json, 'unit'),
    initialAmount: Json.optDouble(json, 'initialAmount'),
    availableAmount: Json.optDouble(json, 'availableAmount'),
    receivedOn: Json.optDateTime(json, 'receivedOn'),
    expiresOn: Json.optDateTime(json, 'expiresOn'),
    status: ReceiptStatus.fromCode(Json.optString(json, 'status')),
    usable: Json.optBool(json, 'usable') ?? false,
    availability: Json.optString(json, 'availability'),
    expirationStatus: Json.optString(json, 'expirationStatus'),
    containerMonitorId: Json.optInt(json, 'containerMonitorId'),
  );
}

class InventoryMovementDto {
  const InventoryMovementDto(this.json);

  final Map<String, dynamic> json;

  InventoryMovement toDomain() => InventoryMovement(
    id: Json.requireInt(json, 'id'),
    type: Json.optString(json, 'type') ?? 'UNKNOWN',
    receiptId: Json.optInt(json, 'receiptId'),
    productBatchId: Json.optInt(json, 'productBatchId'),
    amount: Json.optDouble(json, 'amount'),
    unit: Json.optString(json, 'unit'),
    stockBefore: Json.optDouble(json, 'stockBefore'),
    stockAfter: Json.optDouble(json, 'stockAfter'),
    statusBefore: Json.optString(json, 'statusBefore'),
    statusAfter: Json.optString(json, 'statusAfter'),
    reason: Json.optString(json, 'reason'),
    actorId: Json.optInt(json, 'actorId'),
    occurredAt: Json.optDateTime(json, 'occurredAt'),
  );
}

/// `RawMaterialUsageResource {id, batchId, quantityUsed, unit, usageDate, inventoryReceiptId, ...}`.
class MaterialUsageDto {
  const MaterialUsageDto(this.json);

  final Map<String, dynamic> json;

  MaterialUsage toDomain() => MaterialUsage(
    id: Json.requireInt(json, 'id'),
    batchId: Json.requireInt(json, 'batchId'),
    quantityUsed: Json.optDouble(json, 'quantityUsed'),
    unit: Json.optString(json, 'unit'),
    usageDate: Json.optDateTime(json, 'usageDate'),
    inventoryReceiptId: Json.optInt(json, 'inventoryReceiptId'),
  );
}

/// Read-only access to the Inventory context. Lot registration, reviews,
/// storage and consumptions remain in QualiTrack Web.
class InventoryRemoteDataSource {
  const InventoryRemoteDataSource(this._client);

  final ApiClient _client;

  String _materials(int labId, int environmentId) => '/laboratories/$labId/environments/$environmentId/raw-materials';

  Future<List<InventoryMaterialDto>> getMaterials(int labId, int environmentId) async =>
      Json.asList(await _client.get(_materials(labId, environmentId))).map(InventoryMaterialDto.new).toList();

  Future<InventoryMaterialDto> getMaterial(int labId, int environmentId, int materialId) async =>
      InventoryMaterialDto(Json.asMap(await _client.get('${_materials(labId, environmentId)}/$materialId')));

  Future<List<InventoryReceiptDto>> getReceipts(int labId, int environmentId, int materialId) async => Json.asList(
    await _client.get('${_materials(labId, environmentId)}/$materialId/batches'),
  ).map(InventoryReceiptDto.new).toList();

  Future<List<InventoryMovementDto>> getMovements(int labId, int environmentId, int materialId) async => Json.asList(
    await _client.get('${_materials(labId, environmentId)}/$materialId/movements'),
  ).map(InventoryMovementDto.new).toList();

  Future<List<MaterialUsageDto>> getUsages(int labId, int environmentId, int materialId) async => Json.asList(
    await _client.get('${_materials(labId, environmentId)}/$materialId/usages'),
  ).map(MaterialUsageDto.new).toList();
}

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remote);

  final InventoryRemoteDataSource _remote;

  @override
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, int environmentId) async =>
      (await _remote.getMaterials(laboratoryId.value, environmentId))
          .map((d) => d.toDomain())
          .where((m) => m.laboratoryId == laboratoryId.value && m.environmentId == environmentId)
          .toList(growable: false);

  @override
  Future<InventoryMaterial> getMaterial(LaboratoryId laboratoryId, int environmentId, int materialId) async =>
      (await _remote.getMaterial(laboratoryId.value, environmentId, materialId)).toDomain();

  @override
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      (await _remote.getReceipts(laboratoryId.value, material.environmentId, material.id))
          .map((d) => d.toDomain())
          .toList();

  @override
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      (await _remote.getMovements(laboratoryId.value, material.environmentId, material.id))
          .map((d) => d.toDomain())
          .toList();

  @override
  Future<List<MaterialUsage>> getUsages(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      (await _remote.getUsages(laboratoryId.value, material.environmentId, material.id))
          .map((d) => d.toDomain())
          .toList();
}
