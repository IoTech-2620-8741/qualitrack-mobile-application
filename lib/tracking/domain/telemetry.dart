import 'package:equatable/equatable.dart';

/// `TelemetryStatus` of the Tracking & Telemetry context.
enum TelemetryStatus {
  operational('OPERATIONAL'),
  warning('WARNING'),
  critical('CRITICAL'),
  offline('OFFLINE'),
  unknown('UNKNOWN');

  const TelemetryStatus(this.code);

  final String code;

  static TelemetryStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return TelemetryStatus.unknown;
  }
}

/// `EquipmentTelemetryStatusResource`. When no status was ever reported the
/// backend answers a synthetic `OFFLINE` status with `isOnline = false`.
final class EquipmentTelemetryStatus extends Equatable {
  const EquipmentTelemetryStatus({
    required this.equipmentId,
    required this.isOnline,
    required this.currentStatus,
    this.id,
    this.lastHeartbeat,
    this.rawLastHeartbeat,
  });

  final int? id;
  final int equipmentId;
  final bool isOnline;
  final TelemetryStatus currentStatus;
  final DateTime? lastHeartbeat;
  final String? rawLastHeartbeat;

  bool get needsAttention =>
      currentStatus == TelemetryStatus.warning || currentStatus == TelemetryStatus.critical;

  @override
  List<Object?> get props => [id, equipmentId, isOnline, currentStatus, lastHeartbeat, rawLastHeartbeat];
}

/// `MeasurementResource`: latest readings reported by the edge layer.
final class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.equipmentId,
    required this.parameterName,
    required this.value,
    this.unit,
    this.timestamp,
    this.rawTimestamp,
  });

  final int id;
  final int equipmentId;
  final String parameterName;
  final double value;
  final String? unit;
  final DateTime? timestamp;
  final String? rawTimestamp;

  /// Series identity: the same parameter may be reported with different units.
  String get seriesKey => '${parameterName.trim().toLowerCase()}|${unit ?? ''}';

  @override
  List<Object?> get props => [id, equipmentId, parameterName, value, unit, timestamp, rawTimestamp];
}

/// `TelemetryHistoryPointResource`.
final class TelemetryHistoryPoint extends Equatable {
  const TelemetryHistoryPoint({
    required this.id,
    required this.equipmentId,
    required this.parameterName,
    required this.recordedValue,
    required this.isAnomaly,
    this.timestamp,
    this.rawTimestamp,
  });

  final int id;
  final int equipmentId;
  final String parameterName;
  final double recordedValue;
  final bool isAnomaly;
  final DateTime? timestamp;
  final String? rawTimestamp;

  @override
  List<Object?> get props => [id, equipmentId, parameterName, recordedValue, isAnomaly, timestamp, rawTimestamp];
}

/// Latest reading of one parameter (one card in the dashboard).
final class ParameterReading extends Equatable {
  const ParameterReading({required this.latest, required this.samples});

  final Measurement latest;
  final int samples;

  @override
  List<Object?> get props => [latest, samples];
}

/// Chart window options offered by the telemetry dashboard.
enum TelemetryWindow {
  fifteenMinutes(Duration(minutes: 15)),
  oneHour(Duration(hours: 1)),
  sixHours(Duration(hours: 6)),
  twentyFourHours(Duration(hours: 24));

  const TelemetryWindow(this.duration);

  final Duration duration;
}

/// Pure functions over telemetry collections (no Flutter dependencies).
abstract final class TelemetryAnalysis {
  /// Groups measurements by parameter/unit and keeps the most recent one.
  /// Measurements without a parseable timestamp keep API order.
  static List<ParameterReading> latestByParameter(List<Measurement> measurements) {
    final groups = <String, List<Measurement>>{};
    for (final m in measurements) {
      groups.putIfAbsent(m.seriesKey, () => []).add(m);
    }
    final readings = groups.values.map((items) {
      final sorted = [...items]..sort(_compareMeasurementsDesc);
      return ParameterReading(latest: sorted.first, samples: items.length);
    }).toList();
    readings.sort((a, b) => a.latest.parameterName.compareTo(b.latest.parameterName));
    return readings;
  }

  static int _compareMeasurementsDesc(Measurement a, Measurement b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  /// Distinct parameter names present in the history, sorted.
  static List<String> parameters(List<TelemetryHistoryPoint> points) =>
      (points.map((p) => p.parameterName).toSet().toList()..sort());

  /// Points of [parameter] inside [window], anchored to the most recent real
  /// timestamp (not the device clock), sorted ascending for charting.
  static List<TelemetryHistoryPoint> series(
    List<TelemetryHistoryPoint> points,
    String parameter,
    TelemetryWindow window,
  ) {
    final dated = points
        .where((p) => p.parameterName == parameter && p.timestamp != null)
        .toList()
      ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    if (dated.isEmpty) return const [];
    final end = dated.last.timestamp!;
    final start = end.subtract(window.duration);
    return dated.where((p) => !p.timestamp!.isBefore(start)).toList(growable: false);
  }

  /// A window is offered only when the real data spans more than the
  /// previous (smaller) window, so options always change what is displayed.
  static List<TelemetryWindow> availableWindows(List<TelemetryHistoryPoint> points, String parameter) {
    final dated = points
        .where((p) => p.parameterName == parameter && p.timestamp != null)
        .map((p) => p.timestamp!)
        .toList()
      ..sort();
    if (dated.length < 2) return dated.isEmpty ? const [] : const [TelemetryWindow.fifteenMinutes];
    final span = dated.last.difference(dated.first);
    final result = <TelemetryWindow>[TelemetryWindow.fifteenMinutes];
    for (var i = 1; i < TelemetryWindow.values.length; i++) {
      if (span > TelemetryWindow.values[i - 1].duration) result.add(TelemetryWindow.values[i]);
    }
    return result;
  }

  static List<TelemetryHistoryPoint> anomalies(List<TelemetryHistoryPoint> points) {
    final result = points.where((p) => p.isAnomaly).toList()..sort(_compareHistoryDesc);
    return result;
  }

  static int _compareHistoryDesc(TelemetryHistoryPoint a, TelemetryHistoryPoint b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  static List<TelemetryHistoryPoint> newestFirst(List<TelemetryHistoryPoint> points) =>
      [...points]..sort(_compareHistoryDesc);
}

abstract interface class TelemetryRepository {
  Future<EquipmentTelemetryStatus> getStatus(int equipmentId);
  Future<List<Measurement>> getLatestMeasurements(int equipmentId);
  Future<List<TelemetryHistoryPoint>> getHistory(int equipmentId, {DateTime? from, DateTime? to});
}
