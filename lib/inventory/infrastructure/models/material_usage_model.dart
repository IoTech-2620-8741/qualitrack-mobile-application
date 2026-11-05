import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/material_usage.dart';

/// `RawMaterialUsageResource {id, batchId, quantityUsed, unit, usageDate, inventoryReceiptId, ...}`.
class MaterialUsageModel extends MaterialUsage {
  const MaterialUsageModel({
    required super.id,
    required super.batchId,
    super.quantityUsed,
    super.unit,
    super.usageDate,
    super.inventoryReceiptId,
  });

  factory MaterialUsageModel.fromJson(Map<String, dynamic> json) => MaterialUsageModel(
    id: Json.requireInt(json, 'id'),
    batchId: Json.requireInt(json, 'batchId'),
    quantityUsed: Json.optDouble(json, 'quantityUsed'),
    unit: Json.optString(json, 'unit'),
    usageDate: Json.optDateTime(json, 'usageDate'),
    inventoryReceiptId: Json.optInt(json, 'inventoryReceiptId'),
  );
}
