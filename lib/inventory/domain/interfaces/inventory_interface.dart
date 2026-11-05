import '../../../common/domain/value_objects.dart';
import '../entities/inventory_material.dart';
import '../entities/inventory_movement.dart';
import '../entities/inventory_receipt.dart';
import '../entities/material_usage.dart';

/// Contract of the inventory repository: what can be read about the raw
/// materials of a laboratory, not how. Implemented by the infrastructure layer.
abstract interface class InventoryInterface {
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, int environmentId);
  Future<InventoryMaterial> getMaterial(LaboratoryId laboratoryId, int environmentId, int materialId);
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, InventoryMaterial material);
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, InventoryMaterial material);
  Future<List<MaterialUsage>> getUsages(LaboratoryId laboratoryId, InventoryMaterial material);
}
