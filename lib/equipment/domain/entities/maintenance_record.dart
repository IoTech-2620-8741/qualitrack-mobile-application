import 'package:equatable/equatable.dart';

/// `MaintenanceRecordResource`.
class MaintenanceRecord extends Equatable {
  const MaintenanceRecord({
    required this.id,
    required this.equipmentId,
    this.maintenanceDate,
    this.rawDate,
    this.technicianName,
    this.description,
    this.type,
  });

  final int id;
  final int equipmentId;
  final DateTime? maintenanceDate;
  final String? rawDate;
  final String? technicianName;
  final String? description;
  final String? type;

  @override
  List<Object?> get props => [id, equipmentId, maintenanceDate, rawDate, technicianName, description, type];
}
