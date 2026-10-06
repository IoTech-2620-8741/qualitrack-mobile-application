import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/batch.dart';

/// `BatchResource {id, labId, environmentId, productId, productName, batchNumber,
/// quantity, unit, status, startDate, endDate, notes, containerMonitorId}`.
class BatchDto {
  const BatchDto(this.json);

  final Map<String, dynamic> json;

  ProductionBatch toDomain() => ProductionBatch(
    id: Json.requireInt(json, 'id'),
    labId: Json.requireInt(json, 'labId'),
    environmentId: Json.optInt(json, 'environmentId'),
    productId: Json.requireInt(json, 'productId'),
    productName: Json.optString(json, 'productName'),
    batchNumber: Json.requireString(json, 'batchNumber'),
    quantity: Json.optDouble(json, 'quantity'),
    unit: Json.optString(json, 'unit'),
    status: BatchStatus.fromCode(Json.optString(json, 'status')),
    startDate: Json.optString(json, 'startDate'),
    endDate: Json.optString(json, 'endDate'),
    notes: Json.optString(json, 'notes'),
    containerMonitorId: Json.optInt(json, 'containerMonitorId'),
  );
}

/// `BatchTraceabilityResource {batch, product, rawMaterials, equipment, staff,
/// release, rejection, container}`.
class BatchTraceabilityDto {
  const BatchTraceabilityDto(this.json);

  final Map<String, dynamic> json;

  BatchTraceability toDomain() {
    final product = _object('product');
    final release = _object('release');
    final rejection = _object('rejection');
    final container = _object('container');
    return BatchTraceability(
      batch: BatchDto(Json.asMap(json['batch'])).toDomain(),
      productCode: product == null ? null : Json.optString(product, 'code'),
      rawMaterials: [
        for (final item in _list('rawMaterials'))
          RawMaterialUsage(
            id: Json.requireInt(item, 'id'),
            rawMaterialId: Json.requireInt(item, 'rawMaterialId'),
            rawMaterialName: Json.optString(item, 'rawMaterialName'),
            rawMaterialEnvironmentId: Json.optInt(item, 'rawMaterialEnvironmentId'),
            quantityUsed: Json.optDouble(item, 'quantityUsed'),
            unit: Json.optString(item, 'unit'),
            usageDate: Json.optDateTime(item, 'usageDate'),
            stockBefore: Json.optDouble(item, 'stockBefore'),
            stockAfter: Json.optDouble(item, 'stockAfter'),
            inventoryReceiptId: Json.optInt(item, 'inventoryReceiptId'),
          ),
      ],
      equipment: [
        for (final item in _list('equipment'))
          BatchEquipmentUsage(
            equipmentId: Json.requireInt(item, 'equipmentId'),
            equipmentName: Json.requireString(item, 'equipmentName'),
            registeredAt: Json.optDateTime(item, 'registeredAt'),
          ),
      ],
      staff: [
        for (final item in _list('staff'))
          BatchStaffParticipation(
            staffId: Json.requireInt(item, 'staffId'),
            staffName: Json.requireString(item, 'staffName'),
            staffRole: Json.optString(item, 'staffRole'),
            registeredAt: Json.optDateTime(item, 'registeredAt'),
          ),
      ],
      release: release == null
          ? null
          : BatchRelease(
              signedByUserId: Json.requireInt(release, 'signedByUserId'),
              signatureHash: Json.requireString(release, 'signatureHash'),
              signedAt: Json.optDateTime(release, 'signedAt'),
            ),
      rejection: rejection == null
          ? null
          : BatchRejection(
              reason: Json.requireString(rejection, 'reason'),
              rejectionDate: Json.optString(rejection, 'rejectionDate'),
            ),
      container: container == null
          ? null
          : BatchContainer(
              containerMonitorId: Json.requireInt(container, 'containerMonitorId'),
              containerName: Json.optString(container, 'containerName'),
              environmentId: Json.optInt(container, 'environmentId'),
              assignedAt: Json.optDateTime(container, 'assignedAt'),
            ),
    );
  }

  Map<String, dynamic>? _object(String key) => json[key] == null ? null : Json.asMap(json[key]);

  List<Map<String, dynamic>> _list(String key) => json[key] == null ? const [] : Json.asList(json[key]);
}

class BatchRemoteDataSource {
  const BatchRemoteDataSource(this._client);

  final ApiClient _client;

  String _batch(int labId, ProductionBatch batch) =>
      '/laboratories/$labId/environments/${batch.environmentId}/products/${batch.productId}/batches/${batch.id}';

  Future<List<BatchDto>> getByLab(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/batches')).map(BatchDto.new).toList();

  Future<BatchTraceabilityDto> getTraceability(int labId, ProductionBatch batch) async =>
      BatchTraceabilityDto(Json.asMap(await _client.get('${_batch(labId, batch)}/traceability')));

  Future<void> release(int labId, ProductionBatch batch, String releaseDate, String notes) =>
      _client.post('${_batch(labId, batch)}/releases', body: {'releaseDate': releaseDate, 'notes': notes});

  Future<void> reject(int labId, ProductionBatch batch, String rejectionDate, String reason) =>
      _client.post('${_batch(labId, batch)}/rejections', body: {'rejectionDate': rejectionDate, 'reason': reason});
}

class BatchRepositoryImpl implements BatchRepository {
  const BatchRepositoryImpl(this._remote);

  final BatchRemoteDataSource _remote;

  @override
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getByLab(laboratoryId.value);
    return dtos.map((d) => d.toDomain()).where((b) => b.labId == laboratoryId.value).toList(growable: false);
  }

  @override
  Future<BatchTraceability> getTraceability(LaboratoryId laboratoryId, ProductionBatch batch) async =>
      (await _remote.getTraceability(laboratoryId.value, batch)).toDomain();

  @override
  Future<void> release(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String releaseDate,
    required String notes,
  }) => _remote.release(laboratoryId.value, batch, releaseDate, notes);

  @override
  Future<void> reject(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String rejectionDate,
    required String reason,
  }) => _remote.reject(laboratoryId.value, batch, rejectionDate, reason);
}
