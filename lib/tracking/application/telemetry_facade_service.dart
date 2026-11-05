import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/actuation_event.dart';
import '../domain/entities/device_connection.dart';
import '../domain/entities/environmental_profile.dart';
import '../domain/entities/measurement.dart';
import '../domain/entities/telemetry_target.dart';
import '../domain/interfaces/telemetry_interface.dart';
import '../domain/logic/telemetry_logic.dart';

/// Use cases of Tracking & Telemetry exposed to the presentation layer. It only
/// orchestrates: the rules live in [TelemetryLogic] and the data access behind
/// [TelemetryInterface]. The app never publishes telemetry.
class TelemetryFacadeService with TelemetryLogic {
  const TelemetryFacadeService({required TelemetryInterface repository}) : _repository = repository;

  final TelemetryInterface _repository;

  static const int maxParallel = 4;

  Future<DeviceConnection> getConnection(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _repository.getConnection(laboratoryId, target);

  /// Connection status of many devices with bounded concurrency. Devices whose
  /// status could not be read are absent from the map and are displayed as
  /// "telemetry unavailable"; an authentication problem is rethrown so the
  /// session can be closed.
  Future<Map<int, DeviceConnection>> getConnections(LaboratoryId laboratoryId, List<TelemetryTarget> targets) async {
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

  /// Readings of one device in a period of up to 31 days, newest first.
  Future<List<Measurement>> getMeasurements(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async {
    requireValidPeriod(from, to);
    final points = await _repository.getMeasurements(laboratoryId, target, from: from, to: to);
    return measurementsOfDevice(points, target.deviceId);
  }

  /// Null when no profile was configured yet.
  Future<EnvironmentalProfile?> getProfile(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _repository.getProfile(laboratoryId, target);

  /// Automatic actions of a container monitor, newest first. Environmental
  /// devices do not actuate.
  Future<List<ActuationEvent>> getActuationEvents(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (!target.containerMonitor) return const [];
    return sortEventsNewestFirst(await _repository.getActuationEvents(laboratoryId, target, from: from, to: to));
  }
}
