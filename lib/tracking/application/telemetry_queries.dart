import '../../equipment/domain/equipment.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/telemetry.dart';

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

class GetDeviceConnection {
  const GetDeviceConnection(this._repository);

  final TelemetryRepository _repository;

  Future<DeviceConnection> call(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _repository.getConnection(laboratoryId, target);
}

/// Readings of one device in a period of up to 31 days, newest first. The
/// environment endpoint also returns readings of other devices of the
/// environment, so only those of the target are kept.
class GetMeasurements {
  const GetMeasurements(this._repository);

  final TelemetryRepository _repository;

  Future<List<Measurement>> call(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (!from.isBefore(to) || to.difference(from) > TelemetryAnalysis.maxPeriod) {
      throw const BadRequestFailure(code: 'INVALID_PERIOD');
    }
    final points = await _repository.getMeasurements(laboratoryId, target, from: from, to: to);
    return TelemetryAnalysis.newestFirst(points.where((p) => p.deviceId == target.deviceId).toList());
  }
}

class GetEnvironmentalProfile {
  const GetEnvironmentalProfile(this._repository);

  final TelemetryRepository _repository;

  Future<EnvironmentalProfile?> call(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _repository.getProfile(laboratoryId, target);
}

/// Automatic actions of a container monitor, newest first. Environmental
/// devices do not actuate.
class GetActuationEvents {
  const GetActuationEvents(this._repository);

  final TelemetryRepository _repository;

  Future<List<ActuationEvent>> call(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (!target.containerMonitor) return const [];
    final events = await _repository.getActuationEvents(laboratoryId, target, from: from, to: to);
    return [...events]..sort((a, b) {
      final left = a.occurredAt;
      final right = b.occurredAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

/// Connection status of many devices with bounded concurrency. Devices whose
/// status could not be read are absent from the map and are displayed as
/// "telemetry unavailable"; an authentication problem is rethrown so the
/// session can be closed.
class GetDeviceConnections {
  const GetDeviceConnections(this._repository);

  final TelemetryRepository _repository;

  static const int maxParallel = 4;

  Future<Map<int, DeviceConnection>> call(LaboratoryId laboratoryId, List<TelemetryTarget> targets) async {
    final result = <int, DeviceConnection>{};
    for (var i = 0; i < targets.length; i += maxParallel) {
      final chunk = targets.skip(i).take(maxParallel);
      final connections = await Future.wait(chunk.map((target) => _readOrNull(laboratoryId, target)));
      for (final connection in connections.whereType<DeviceConnection>()) {
        result[connection.deviceId] = connection;
      }
    }
    return result;
  }

  Future<DeviceConnection?> _readOrNull(LaboratoryId laboratoryId, TelemetryTarget target) async {
    try {
      return await _repository.getConnection(laboratoryId, target);
    } on UnauthorizedFailure {
      rethrow;
    } on OnboardingRequiredFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }
}
