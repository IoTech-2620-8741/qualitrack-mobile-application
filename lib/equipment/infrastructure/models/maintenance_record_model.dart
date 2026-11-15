import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/maintenance_record.dart';

/// `MaintenanceRecordResource`.
class MaintenanceRecordModel extends MaintenanceRecord {
  const MaintenanceRecordModel({
    required super.id,
    required super.equipmentId,
    super.maintenanceDate,
    super.rawDate,
    super.technicianName,
    super.description,
    super.type,
  });

  factory MaintenanceRecordModel.fromJson(Map<String, dynamic> json) => MaintenanceRecordModel(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    maintenanceDate: Json.optDateTime(json, 'maintenanceDate'),
    rawDate: Json.optString(json, 'maintenanceDate'),
    technicianName: Json.optString(json, 'technicianName'),
    description: Json.optString(json, 'description'),
    type: Json.optString(json, 'type'),
  );
}
