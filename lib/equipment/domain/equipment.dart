import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// `EquipmentStatus` of the Equipment Management context. The API exposes it
/// as a String, so unknown values are preserved in [Equipment.rawStatus].
enum EquipmentStatus {
  operational('OPERATIONAL'),
  maintenance('MAINTENANCE'),
  outOfService('OUT_OF_SERVICE'),
  inactive('INACTIVE'),
  unknown('UNKNOWN');

  const EquipmentStatus(this.code);

  final String code;

  static EquipmentStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return EquipmentStatus.unknown;
  }
}

/// `EquipmentResource`.
final class Equipment extends Equatable {
  const Equipment({
    required this.id,
    required this.laboratoryId,
    required this.name,
    required this.status,
    this.rawStatus,
    this.type,
    this.model,
    this.serialNumber,
    this.sensorExternalId,
  });

  final int id;
  final int laboratoryId;
  final String name;
  final String? type;
  final String? model;
  final String? serialNumber;
  final EquipmentStatus status;
  final String? rawStatus;
  final String? sensorExternalId;

  bool get hasSensor => sensorExternalId != null && sensorExternalId!.trim().isNotEmpty;

  /// Equipment that is not operational requires attention.
  bool get needsAttention =>
      status == EquipmentStatus.maintenance || status == EquipmentStatus.outOfService;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [name, type, model, serialNumber, sensorExternalId]
        .whereType<String>()
        .any((field) => field.toLowerCase().contains(q));
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    name,
    type,
    model,
    serialNumber,
    status,
    rawStatus,
    sensorExternalId,
  ];
}

/// `MaintenanceRecordResource`.
final class MaintenanceRecord extends Equatable {
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

/// `BpmParameterConfigResource`: acceptance limits configured in Web.
final class BpmParameterConfig extends Equatable {
  const BpmParameterConfig({
    required this.id,
    required this.equipmentId,
    required this.parameterName,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  final int id;
  final int equipmentId;
  final String parameterName;
  final double? minValue;
  final double? maxValue;
  final String? unit;

  /// Case-insensitive match between a telemetry parameter and this limit.
  bool appliesTo(String parameter) =>
      parameterName.trim().toLowerCase() == parameter.trim().toLowerCase();

  bool isWithin(double value) =>
      (minValue == null || value >= minValue!) && (maxValue == null || value <= maxValue!);

  @override
  List<Object?> get props => [id, equipmentId, parameterName, minValue, maxValue, unit];
}

abstract interface class EquipmentRepository {
  Future<List<Equipment>> getByLaboratory(LaboratoryId laboratoryId);
  Future<Equipment> getById(int equipmentId);
  Future<List<MaintenanceRecord>> getMaintenance(int equipmentId);
  Future<List<BpmParameterConfig>> getBpmConfigs(int equipmentId);
}
