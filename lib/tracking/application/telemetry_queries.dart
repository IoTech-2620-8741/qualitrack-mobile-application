import '../../shared/domain/failure.dart';
import '../domain/telemetry.dart';

class GetTelemetryStatus {
  const GetTelemetryStatus(this._repository);

  final TelemetryRepository _repository;

  Future<EquipmentTelemetryStatus> call(int equipmentId) => _repository.getStatus(equipmentId);
}

class GetLatestTelemetry {
  const GetLatestTelemetry(this._repository);

  final TelemetryRepository _repository;

  Future<List<ParameterReading>> call(int equipmentId) async {
    final measurements = await _repository.getLatestMeasurements(equipmentId);
    return TelemetryAnalysis.latestByParameter(
      measurements.where((m) => m.equipmentId == equipmentId && m.value.isFinite).toList(),
    );
  }
}

class GetTelemetryHistory {
  const GetTelemetryHistory(this._repository);

  final TelemetryRepository _repository;

  /// The backend only applies the range when both bounds are present.
  Future<List<TelemetryHistoryPoint>> call(
    int equipmentId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final hasRange = from != null && to != null;
    final points = await _repository.getHistory(
      equipmentId,
      from: hasRange ? from : null,
      to: hasRange ? to : null,
    );
    return TelemetryAnalysis.newestFirst(
      points.where((p) => p.equipmentId == equipmentId && p.recordedValue.isFinite).toList(),
    );
  }
}

/// Loads telemetry status for many equipments with bounded concurrency
/// (same approach as the Web dashboard: 4 parallel requests).
class GetTelemetryStatuses {
  const GetTelemetryStatuses(this._repository);

  final TelemetryRepository _repository;

  static const int maxParallel = 4;

  /// Equipments whose status could not be read are absent from the map and
  /// are displayed as "telemetry unavailable". An authentication problem is
  /// rethrown so the session can be closed.
  Future<Map<int, EquipmentTelemetryStatus>> call(List<int> equipmentIds) async {
    final result = <int, EquipmentTelemetryStatus>{};
    for (var i = 0; i < equipmentIds.length; i += maxParallel) {
      final chunk = equipmentIds.skip(i).take(maxParallel);
      final statuses = await Future.wait(chunk.map(_readOrNull));
      for (final status in statuses.whereType<EquipmentTelemetryStatus>()) {
        result[status.equipmentId] = status;
      }
    }
    return result;
  }

  Future<EquipmentTelemetryStatus?> _readOrNull(int equipmentId) async {
    try {
      return await _repository.getStatus(equipmentId);
    } on UnauthorizedFailure {
      rethrow;
    } on OnboardingRequiredFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }
}
