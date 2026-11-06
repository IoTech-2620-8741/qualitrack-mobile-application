import '../../common/application/bounded_concurrency.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/inventory_material.dart';
import '../domain/entities/inventory_movement.dart';
import '../domain/entities/inventory_receipt.dart';
import '../domain/entities/material_usage.dart';
import '../domain/interfaces/inventory_interface.dart';
import '../domain/logic/inventory_logic.dart';

/// Use cases of Inventory Management exposed to the presentation layer. It only
/// orchestrates: the rules live in [InventoryLogic] and the data access behind
/// [InventoryInterface].
class InventoryFacadeService with InventoryLogic {
  const InventoryFacadeService({required InventoryInterface repository}) : _repository = repository;

  final InventoryInterface _repository;

  /// Raw materials of every given environment (the backend lists them per
  /// environment): materials below minimum first, then alphabetical.
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, Iterable<int> environmentIds) async =>
      sortMaterials(await loadAll(environmentIds, (id) => _repository.getMaterials(laboratoryId, id)));

  Future<InventoryMaterial> getMaterial(LaboratoryId laboratoryId, int environmentId, int materialId) =>
      _repository.getMaterial(laboratoryId, environmentId, materialId);

  /// Lots of the material, most recent reception first.
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      sortReceipts(await _repository.getReceipts(laboratoryId, material));

  /// Receipts, reviews, storage and consumptions of the material, newest first.
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      sortMovements(await _repository.getMovements(laboratoryId, material));

  /// Product batches that consumed the material (traceability by material).
  Future<List<MaterialUsage>> getUsages(LaboratoryId laboratoryId, InventoryMaterial material) async =>
      sortUsages(await _repository.getUsages(laboratoryId, material));
}
