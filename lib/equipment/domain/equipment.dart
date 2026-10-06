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

/// `IotDeviceType`: the IoT role of an equipment, if it has one. An
/// environmental device supervises a whole environment (one per environment);
/// a container monitor supervises a container where lots are stored.
enum IotDeviceType {
  environmentalDevice('ENVIRONMENTAL_DEVICE'),
  containerMonitor('CONTAINER_MONITOR');

  const IotDeviceType(this.code);

  final String code;

  static IotDeviceType? fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// `EquipmentResource`.
final class Equipment extends Equatable {
  const Equipment({
    required this.id,
    required this.laboratoryId,
    required this.name,
    required this.status,
    this.environmentId,
    this.rawStatus,
    this.type,
    this.model,
    this.serialNumber,
    this.deviceType,
    this.sensorExternalId,
    this.firmwareVersion,
  });

  final int id;
  final int laboratoryId;

  /// Environment where the equipment is located, if it was located already.
  final int? environmentId;
  final String name;
  final String? type;
  final String? model;
  final String? serialNumber;
  final EquipmentStatus status;
  final String? rawStatus;
  final IotDeviceType? deviceType;
  final String? sensorExternalId;
  final String? firmwareVersion;

  /// Only IoT devices report telemetry (environmental devices and container monitors).
  bool get isIotDevice => deviceType != null;

  bool get isContainerMonitor => deviceType == IotDeviceType.containerMonitor;

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
    environmentId,
    name,
    type,
    model,
    serialNumber,
    status,
    rawStatus,
    deviceType,
    sensorExternalId,
    firmwareVersion,
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
  Future<Equipment> getById(LaboratoryId laboratoryId, int equipmentId);
  Future<List<MaintenanceRecord>> getMaintenance(LaboratoryId laboratoryId, int environmentId, int equipmentId);
  Future<List<BpmParameterConfig>> getBpmConfigs(LaboratoryId laboratoryId, int equipmentId);
}
