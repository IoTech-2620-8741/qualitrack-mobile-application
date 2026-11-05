import '../entities/equipment.dart';
import '../entities/maintenance_record.dart';

/// Business rules of Equipment Management. Pure Dart: the facade applies them
/// on top of the repository.
mixin EquipmentLogic {
  /// Equipment ordered by name.
  List<Equipment> sortByName(List<Equipment> equipments) =>
      [...equipments]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Newest maintenance first; undated records go last, newest id first.
  List<MaintenanceRecord> sortMaintenanceNewestFirst(List<MaintenanceRecord> records) => [...records]
    ..sort((a, b) {
      final left = a.maintenanceDate;
      final right = b.maintenanceDate;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
}
