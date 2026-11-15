import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/inventory_material.dart';

/// `RawMaterialResource`.
class InventoryMaterialModel extends InventoryMaterial {
  const InventoryMaterialModel({
    required super.id,
    required super.laboratoryId,
    required super.environmentId,
    required super.code,
    required super.name,
    required super.unit,
    required super.minimumStock,
    required super.usableStock,
    required super.physicalStock,
    super.stockStatus,
    super.legacyId,
  });

  factory InventoryMaterialModel.fromJson(Map<String, dynamic> json) => InventoryMaterialModel(
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
