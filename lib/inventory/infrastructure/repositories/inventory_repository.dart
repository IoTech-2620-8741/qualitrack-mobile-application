import '../../../common/domain/value_objects.dart';
import '../../domain/entities/inventory_material.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_receipt.dart';
import '../../domain/entities/material_usage.dart';
import '../../domain/interfaces/inventory_interface.dart';
import '../data_sources/inventory_remote_data_provider.dart';

/// Implements [InventoryInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider. Materials of another
/// laboratory or environment are dropped.
class InventoryRepository implements InventoryInterface {
  const InventoryRepository({required InventoryRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final InventoryRemoteDataProvider _remote;

  @override
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, int environmentId) async =>
      List<InventoryMaterial>.of(
        (await _remote.getMaterials(laboratoryId.value, environmentId))
            .where((m) => m.laboratoryId == laboratoryId.value && m.environmentId == environmentId),
        growable: false,
      );

  @override
  Future<InventoryMaterial> getMaterial(LaboratoryId laboratoryId, int environmentId, int materialId) =>
      _remote.getMaterial(laboratoryId.value, environmentId, materialId);

  @override
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, InventoryMaterial material) =>
      _remote.getReceipts(laboratoryId.value, material.environmentId, material.id);

  @override
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, InventoryMaterial material) =>
      _remote.getMovements(laboratoryId.value, material.environmentId, material.id);

  @override
  Future<List<MaterialUsage>> getUsages(LaboratoryId laboratoryId, InventoryMaterial material) =>
      _remote.getUsages(laboratoryId.value, material.environmentId, material.id);
}
