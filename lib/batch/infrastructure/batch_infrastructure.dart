import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/batch.dart';

class BatchDto {
  const BatchDto(this.json);

  final Map<String, dynamic> json;

  ProductionBatch toDomain() => ProductionBatch(
    id: Json.requireInt(json, 'id'),
    labId: Json.requireInt(json, 'labId'),
    productId: Json.optInt(json, 'productId'),
    productName: Json.optString(json, 'productName'),
    batchNumber: Json.requireString(json, 'batchNumber'),
    quantity: Json.optDouble(json, 'quantity'),
    unit: Json.optString(json, 'unit'),
    status: BatchStatus.fromCode(Json.optString(json, 'status')),
    startDate: Json.optString(json, 'startDate'),
    endDate: Json.optString(json, 'endDate'),
    notes: Json.optString(json, 'notes'),
  );
}

class RawMaterialUsageDto {
  const RawMaterialUsageDto(this.json);

  final Map<String, dynamic> json;

  RawMaterialUsage toDomain() => RawMaterialUsage(
    id: Json.requireInt(json, 'id'),
    batchId: Json.requireInt(json, 'batchId'),
    rawMaterialId: Json.requireInt(json, 'rawMaterialId'),
    rawMaterialName: Json.optString(json, 'rawMaterialName'),
    quantityUsed: Json.optDouble(json, 'quantityUsed'),
    unit: Json.optString(json, 'unit'),
    usageDate: Json.optDateTime(json, 'usageDate'),
    rawUsageDate: Json.optString(json, 'usageDate'),
    stockBefore: Json.optDouble(json, 'stockBefore'),
    stockAfter: Json.optDouble(json, 'stockAfter'),
    inventoryReceiptId: Json.optInt(json, 'inventoryReceiptId'),
  );
}

/// `UpdateBatchStatusResource`.
class UpdateBatchStatusRequest {
  const UpdateBatchStatusRequest.release({required this.releaseDate, required this.notes})
    : status = BatchStatus.released,
      rejectionDate = null,
      reason = null;

  const UpdateBatchStatusRequest.reject({required this.rejectionDate, required this.reason})
    : status = BatchStatus.rejected,
      releaseDate = null,
      notes = null;

  final BatchStatus status;
  final String? releaseDate;
  final String? notes;
  final String? rejectionDate;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'status': status.code,
    if (releaseDate != null) 'releaseDate': releaseDate,
    if (notes != null) 'notes': notes,
    if (rejectionDate != null) 'rejectionDate': rejectionDate,
    if (reason != null) 'reason': reason,
  };
}

class BatchRemoteDataSource {
  const BatchRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<BatchDto>> getByLab(int labId) async => Json.asList(
    await _client.get('/batches', query: {'labId': labId}),
  ).map(BatchDto.new).toList();

  Future<BatchDto> getById(int batchId) async =>
      BatchDto(Json.asMap(await _client.get('/batches/$batchId')));

  Future<List<RawMaterialUsageDto>> getUsage(int batchId) async => Json.asList(
    await _client.get('/batches/$batchId/raw-materials'),
  ).map(RawMaterialUsageDto.new).toList();

  Future<BatchDto> updateStatus(int batchId, UpdateBatchStatusRequest request) async =>
      BatchDto(Json.asMap(await _client.patch('/batches/$batchId', body: request.toJson())));
}

class BatchRepositoryImpl implements BatchRepository {
  const BatchRepositoryImpl(this._remote);

  final BatchRemoteDataSource _remote;

  @override
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getByLab(laboratoryId.value);
    return dtos
        .map((d) => d.toDomain())
        .where((b) => b.labId == laboratoryId.value)
        .toList(growable: false);
  }

  @override
  Future<ProductionBatch> getById(int batchId) async => (await _remote.getById(batchId)).toDomain();

  @override
  Future<List<RawMaterialUsage>> getRawMaterialUsage(int batchId) async =>
      (await _remote.getUsage(batchId)).map((d) => d.toDomain()).toList(growable: false);

  @override
  Future<ProductionBatch> release({
    required int batchId,
    required String releaseDate,
    required String notes,
  }) async {
    final dto = await _remote.updateStatus(
      batchId,
      UpdateBatchStatusRequest.release(releaseDate: releaseDate, notes: notes),
    );
    return dto.toDomain();
  }

  @override
  Future<ProductionBatch> reject({
    required int batchId,
    required String rejectionDate,
    required String reason,
  }) async {
    final dto = await _remote.updateStatus(
      batchId,
      UpdateBatchStatusRequest.reject(rejectionDate: rejectionDate, reason: reason),
    );
    return dto.toDomain();
  }
}
