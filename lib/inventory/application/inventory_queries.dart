import '../../shared/application/bounded_concurrency.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/inventory.dart';

/// Raw materials of every given environment (the backend lists them per
/// environment): materials below minimum first, then alphabetical.
class GetInventoryMaterials {
  const GetInventoryMaterials(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryMaterial>> call(LaboratoryId laboratoryId, Iterable<int> environmentIds) async {
    final materials = await loadAll(environmentIds, (id) => _repository.getMaterials(laboratoryId, id));
    return materials..sort((a, b) {
      final low = (b.isBelowMinimum ? 1 : 0).compareTo(a.isBelowMinimum ? 1 : 0);
      return low != 0 ? low : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}

class GetInventoryMaterial {
  const GetInventoryMaterial(this._repository);

  final InventoryRepository _repository;

  Future<InventoryMaterial> call(LaboratoryId laboratoryId, int environmentId, int materialId) =>
      _repository.getMaterial(laboratoryId, environmentId, materialId);
}

/// Lots of the material, most recent reception first.
class GetMaterialReceipts {
  const GetMaterialReceipts(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryReceipt>> call(LaboratoryId laboratoryId, InventoryMaterial material) async {
    final receipts = await _repository.getReceipts(laboratoryId, material);
    return [...receipts]..sort((a, b) {
      final left = a.receivedOn;
      final right = b.receivedOn;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

/// Receipts, reviews, storage and consumptions of the material, newest first.
class GetInventoryMovements {
  const GetInventoryMovements(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryMovement>> call(LaboratoryId laboratoryId, InventoryMaterial material) async {
    final movements = await _repository.getMovements(laboratoryId, material);
    return [...movements]..sort((a, b) {
      final left = a.occurredAt;
      final right = b.occurredAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

/// Product batches that consumed the material (traceability by material).
class GetMaterialUsages {
  const GetMaterialUsages(this._repository);

  final InventoryRepository _repository;

  Future<List<MaterialUsage>> call(LaboratoryId laboratoryId, InventoryMaterial material) async {
    final usages = await _repository.getUsages(laboratoryId, material);
    return [...usages]..sort((a, b) {
      final left = a.usageDate;
      final right = b.usageDate;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}
