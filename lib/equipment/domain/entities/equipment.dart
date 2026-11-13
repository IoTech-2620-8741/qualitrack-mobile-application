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

  /// Edge Gateway (Raspberry Pi) of an environment: an equipment of type
  /// `EDGE_GATEWAY` with no device type, which forwards the readings of the
  /// IoT devices of its environment to the platform.
  bool get isEdgeGateway => type == edgeGatewayType;

  /// Type the backend stores for an Edge Gateway.
  static const String edgeGatewayType = 'EDGE_GATEWAY';

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
