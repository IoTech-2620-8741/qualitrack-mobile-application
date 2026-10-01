import '../../shared/domain/value_objects.dart';
import '../domain/inventory.dart';

class GetInventoryMaterials {
  const GetInventoryMaterials(this._repository);

  final InventoryRepository _repository;

  /// Materials below minimum first, then alphabetical.
  Future<List<InventoryMaterial>> call(LaboratoryId laboratoryId) async {
    final materials = await _repository.getMaterials(laboratoryId);
    return [...materials]..sort((a, b) {
      final low = (b.isBelowMinimum ? 1 : 0).compareTo(a.isBelowMinimum ? 1 : 0);
      return low != 0 ? low : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}

class GetMaterialReceipts {
  const GetMaterialReceipts(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryReceipt>> call(LaboratoryId laboratoryId, int materialId) async {
    final receipts = await _repository.getReceipts(laboratoryId, materialId);
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

class GetInventoryMovements {
  const GetInventoryMovements(this._repository);

  final InventoryRepository _repository;

  Future<List<InventoryMovement>> call(LaboratoryId laboratoryId, int materialId) async {
    final movements = await _repository.getMovements(laboratoryId, materialId);
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
