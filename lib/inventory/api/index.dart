/// Public entry point of the Inventory Management context. Other bounded
/// contexts read the inventory through [InventoryApi] and never import the
/// domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/inventory_facade_service.dart';
import '../domain/entities/inventory_material.dart';

export '../domain/entities/inventory_material.dart';

class InventoryApi {
  const InventoryApi(this._inventoryService);

  final InventoryFacadeService _inventoryService;

  /// Raw materials of the given environments, below minimum first.
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, Iterable<int> environmentIds) =>
      _inventoryService.getMaterials(laboratoryId, environmentIds);
}
