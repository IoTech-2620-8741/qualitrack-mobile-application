import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/batch_status.dart';
import '../../domain/entities/production_batch.dart';

/// `BatchResource {id, labId, environmentId, productId, productName, batchNumber,
/// quantity, unit, status, startDate, endDate, notes, containerMonitorId}`.
class ProductionBatchModel extends ProductionBatch {
  const ProductionBatchModel({
    required super.id,
    required super.labId,
    required super.productId,
    required super.batchNumber,
    required super.status,
    super.environmentId,
    super.productName,
    super.quantity,
    super.unit,
    super.startDate,
    super.endDate,
    super.notes,
    super.containerMonitorId,
  });

  factory ProductionBatchModel.fromJson(Map<String, dynamic> json) => ProductionBatchModel(
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
