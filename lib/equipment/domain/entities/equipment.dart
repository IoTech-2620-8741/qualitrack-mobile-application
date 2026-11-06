import 'package:equatable/equatable.dart';

import 'equipment_status.dart';
import 'iot_device_type.dart';

/// `EquipmentResource`.
class Equipment extends Equatable {
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
