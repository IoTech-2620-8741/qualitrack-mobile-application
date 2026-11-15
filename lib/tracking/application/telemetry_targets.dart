import '../../equipment/api/index.dart';
import '../domain/entities/telemetry_target.dart';

/// IoT devices that can report telemetry: equipment with an IoT role that is
/// located in an environment (as in QualiTrack Web).
List<Equipment> telemetryDevices(List<Equipment> equipments) =>
    equipments.where((e) => e.isIotDevice && e.environmentId != null).toList(growable: false);

TelemetryTarget? targetOf(Equipment equipment) {
  final environmentId = equipment.environmentId;
  if (!equipment.isIotDevice || environmentId == null) return null;
  return TelemetryTarget(
    deviceId: equipment.id,
    environmentId: environmentId,
    containerMonitor: equipment.isContainerMonitor,
  );
}
