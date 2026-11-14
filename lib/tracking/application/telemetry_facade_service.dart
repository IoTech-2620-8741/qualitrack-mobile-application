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
  Future<Map<int, DeviceConnection>> getConnections(LaboratoryId laboratoryId, List<TelemetryTarget> targets) =>
      _readEach(targets, (target) => _repository.getConnection(laboratoryId, target));

  /// The profile each device applies, by device id; devices without one, or
  /// that cannot be read, are absent.
  Future<Map<int, EnvironmentalProfile>> getProfiles(LaboratoryId laboratoryId, List<TelemetryTarget> targets) =>
      _readEach(targets, (target) => _repository.getProfile(laboratoryId, target));

  /// [read] of each target, by device id, at most [maxParallel] at a time. A
  /// target that reads null or fails is absent; an authentication problem is
  /// rethrown so the session can be closed.
  Future<Map<int, T>> _readEach<T extends Object>(
    List<TelemetryTarget> targets,
    Future<T?> Function(TelemetryTarget target) read,
  ) async {
    Future<T?> readOrNull(TelemetryTarget target) async {
      try {
        return await read(target);
      } on UnauthorizedFailure {
        rethrow;
      } on OnboardingRequiredFailure {
        rethrow;
      } on Failure {
        return null;
      }
    }

    final result = <int, T>{};
    for (var i = 0; i < targets.length; i += maxParallel) {
      final chunk = targets.skip(i).take(maxParallel).toList();
      final values = await Future.wait(chunk.map(readOrNull));
      for (final (index, value) in values.indexed) {
        if (value != null) result[chunk[index].deviceId] = value;
      }
    }
    return result;
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
