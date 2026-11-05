import '../entities/inventory_material.dart';
import '../entities/inventory_movement.dart';
import '../entities/inventory_receipt.dart';
import '../entities/material_usage.dart';

/// Business rules of Inventory Management. Pure Dart: the facade applies them
/// on top of the repository.
mixin InventoryLogic {
  /// Materials below the minimum first, then alphabetical.
  List<InventoryMaterial> sortMaterials(List<InventoryMaterial> materials) => [...materials]
    ..sort((a, b) {
      final low = (b.isBelowMinimum ? 1 : 0).compareTo(a.isBelowMinimum ? 1 : 0);
      return low != 0 ? low : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  /// Most recent reception first.
  List<InventoryReceipt> sortReceipts(List<InventoryReceipt> receipts) =>
      _newestFirst(receipts, (r) => r.receivedOn, (r) => r.id);

  /// Newest movement first.
  List<InventoryMovement> sortMovements(List<InventoryMovement> movements) =>
      _newestFirst(movements, (m) => m.occurredAt, (m) => m.id);

  /// Most recent usage first.
  List<MaterialUsage> sortUsages(List<MaterialUsage> usages) =>
      _newestFirst(usages, (u) => u.usageDate, (u) => u.id);

  /// Undated rows go last, newest id first.
  List<T> _newestFirst<T>(List<T> items, DateTime? Function(T) date, int Function(T) id) => [...items]
    ..sort((a, b) {
      final left = date(a);
      final right = date(b);
      if (left == null && right == null) return id(b).compareTo(id(a));
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
}
