import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/inventory_movement.dart';

/// `InventoryMovementResource`.
class InventoryMovementModel extends InventoryMovement {
  const InventoryMovementModel({
    required super.id,
    required super.type,
    super.receiptId,
    super.productBatchId,
    super.amount,
    super.unit,
    super.stockBefore,
    super.stockAfter,
    super.statusBefore,
    super.statusAfter,
    super.reason,
    super.actorId,
    super.occurredAt,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) => InventoryMovementModel(
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
