import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/inventory_receipt.dart';
import '../../domain/entities/receipt_status.dart';

/// `ReceiptResource`.
class InventoryReceiptModel extends InventoryReceipt {
  const InventoryReceiptModel({
    required super.id,
    required super.rawMaterialId,
    required super.status,
    required super.usable,
    super.supplier,
    super.batchNumber,
    super.unit,
    super.initialAmount,
    super.availableAmount,
    super.receivedOn,
    super.expiresOn,
    super.availability,
    super.expirationStatus,
    super.containerMonitorId,
  });

  factory InventoryReceiptModel.fromJson(Map<String, dynamic> json) => InventoryReceiptModel(
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
