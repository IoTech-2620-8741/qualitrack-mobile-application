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
    code: Json.optString(json, 'code') ?? '',
    name: Json.requireString(json, 'name'),
    unit: Json.optString(json, 'unit') ?? '',
    minimumStock: Json.optDouble(json, 'minimumStock') ?? 0,
    usableStock: Json.optDouble(json, 'usableStock') ?? 0,
    physicalStock: Json.optDouble(json, 'physicalStock') ?? 0,
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

/// Read-only access to the Inventory context. Receipt registration, reviews,
/// consumptions and legacy imports remain in QualiTrack Web.
class InventoryRemoteDataSource {
  const InventoryRemoteDataSource(this._client);

  final ApiClient _client;

  String _base(int labId) => '/laboratories/$labId/inventory';

  Future<List<InventoryMaterialDto>> getMaterials(int labId) async => Json.asList(
    await _client.get('${_base(labId)}/materials'),
  ).map(InventoryMaterialDto.new).toList();

  Future<List<InventoryReceiptDto>> getReceipts(int labId, int materialId) async => Json.asList(
    await _client.get('${_base(labId)}/materials/$materialId/receipts'),
  ).map(InventoryReceiptDto.new).toList();

  Future<List<InventoryMovementDto>> getMovements(int labId, int materialId) async => Json.asList(
    await _client.get('${_base(labId)}/materials/$materialId/movements'),
  ).map(InventoryMovementDto.new).toList();
}

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remote);

  final InventoryRemoteDataSource _remote;

  @override
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getMaterials(laboratoryId.value);
    return dtos
        .map((d) => d.toDomain())
        .where((m) => m.laboratoryId == laboratoryId.value)
        .toList(growable: false);
  }

  @override
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, int materialId) async =>
      (await _remote.getReceipts(laboratoryId.value, materialId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, int materialId) async =>
      (await _remote.getMovements(laboratoryId.value, materialId)).map((d) => d.toDomain()).toList();
}
