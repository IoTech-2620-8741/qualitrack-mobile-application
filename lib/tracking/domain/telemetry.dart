import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// `MonitoredMetric` of Tracking & Telemetry. Environmental devices measure
/// air quality and motion; container monitors measure temperature, humidity,
/// luminosity and read RFID tags.
enum MonitoredMetric {
  airQuality('AIR_QUALITY'),
  motion('MOTION'),
  temperature('TEMPERATURE'),
  humidity('HUMIDITY'),
  luminosity('LUMINOSITY'),
  rfidTag('RFID_TAG'),
  unknown('');

  const MonitoredMetric(this.code);

  final String code;

  /// Metrics with a numeric value that can be charted against thresholds.
  bool get isNumeric => this != motion && this != rfidTag && this != unknown;

  static MonitoredMetric fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return MonitoredMetric.unknown;
  }
}

/// `EnvironmentalState`: how a reading was evaluated in Cloud against the
/// profile that was in force.
enum EnvironmentalState {
  normal('NORMAL'),
  warning('WARNING'),
  critical('CRITICAL'),
  unknown('');

  const EnvironmentalState(this.code);

  final String code;

  bool get isDeviation => this == warning || this == critical;

  static EnvironmentalState fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return EnvironmentalState.unknown;
  }
}

/// `DeviceConnectionStatus` (TS41): a device that has not communicated within
/// its expected period requires review.
enum ConnectionStatus {
  connected('CONNECTED'),
  requiresReview('REQUIRES_REVIEW'),
  unknown('');

  const ConnectionStatus(this.code);

  final String code;

  static ConnectionStatus fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return ConnectionStatus.unknown;
  }
}

/// An IoT device whose telemetry is read: the environmental device of an
/// environment or a container monitor located in it.
final class TelemetryTarget extends Equatable {
  const TelemetryTarget({
    required this.deviceId,
    required this.environmentId,
    required this.containerMonitor,
  });

  final int deviceId;
  final int environmentId;
  final bool containerMonitor;

  @override
  List<Object?> get props => [deviceId, environmentId, containerMonitor];
}

/// `DeviceTelemetryStatusResource`.
final class DeviceConnection extends Equatable {
  const DeviceConnection({
    required this.deviceId,
    required this.status,
    this.lastCommunicationAt,
    this.expectedPeriodSeconds,
  });

  final int deviceId;
  final ConnectionStatus status;
  final DateTime? lastCommunicationAt;
  final int? expectedPeriodSeconds;

  bool get isConnected => status == ConnectionStatus.connected;

  @override
  List<Object?> get props => [deviceId, status, lastCommunicationAt, expectedPeriodSeconds];
}

/// `MeasurementResource`: a reading evaluated in Cloud.
final class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.deviceId,
    required this.environmentId,
    required this.metric,
    required this.rawMetric,
    required this.state,
    this.value,
    this.textValue,
    this.unit,
    this.measuredAt,
    this.thresholdValue,
    this.profileVersion,
  });

  final int id;
  final int deviceId;
  final int environmentId;
  final MonitoredMetric metric;

  /// Metric code as sent by the backend (kept for metrics unknown to the app).
  final String rawMetric;
  final double? value;
  final String? textValue;
  final String? unit;
  final DateTime? measuredAt;
  final EnvironmentalState state;

  /// Limit that was exceeded, when the reading is a deviation.
  final double? thresholdValue;
  final int? profileVersion;

  bool get isNumeric => metric.isNumeric && value != null && value!.isFinite;

  @override
  List<Object?> get props => [
    id,
    deviceId,
    environmentId,
    metric,
    rawMetric,
    value,
    textValue,
    unit,
    measuredAt,
    state,
    thresholdValue,
    profileVersion,
  ];
}

/// Normal and critical range of one metric. Readings outside the normal range
/// are warnings; outside the critical range, critical.
final class MetricThreshold extends Equatable {
  const MetricThreshold({
    required this.metric,
    this.unit,
    this.normalMin,
    this.normalMax,
    this.criticalMin,
    this.criticalMax,
  });

  final MonitoredMetric metric;
  final String? unit;
  final double? normalMin;
  final double? normalMax;
  final double? criticalMin;
  final double? criticalMax;

  @override
  List<Object?> get props => [metric, unit, normalMin, normalMax, criticalMin, criticalMax];
}

/// Automatic response of a container: the action executed when a metric
/// reaches a state.
final class ActuationRule extends Equatable {
  const ActuationRule({required this.metric, required this.state, required this.action});

  final MonitoredMetric metric;
  final EnvironmentalState state;
  final String action;

  @override
  List<Object?> get props => [metric, state, action];
}

/// `EnvironmentalProfileResource`: versioned thresholds (and rules for
/// container monitors) configured in QualiTrack Web.
final class EnvironmentalProfile extends Equatable {
  const EnvironmentalProfile({
    required this.version,
    this.thresholds = const [],
    this.actuationRules = const [],
    this.updatedAt,
  });

  final int version;
  final List<MetricThreshold> thresholds;
  final List<ActuationRule> actuationRules;
  final DateTime? updatedAt;

  MetricThreshold? thresholdFor(MonitoredMetric metric) {
    for (final threshold in thresholds) {
      if (threshold.metric == metric) return threshold;
    }
    return null;
  }

  @override
  List<Object?> get props => [version, thresholds, actuationRules, updatedAt];
}

/// `ActuationEventResource`: an action executed by a container monitor.
final class ActuationEvent extends Equatable {
  const ActuationEvent({
    required this.id,
    required this.deviceId,
    required this.action,
    required this.result,
    this.triggerMetric,
    this.triggerState,
    this.occurredAt,
  });

  final int id;
  final int deviceId;
  final String action;
  final String result;
  final MonitoredMetric? triggerMetric;
  final EnvironmentalState? triggerState;
  final DateTime? occurredAt;

  bool get executed => result == 'EXECUTED';

  @override
  List<Object?> get props => [id, deviceId, action, result, triggerMetric, triggerState, occurredAt];
}

/// Latest reading of one metric (one card in the dashboard).
final class MetricReading extends Equatable {
  const MetricReading({required this.latest, required this.samples});

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
  /// The backend accepts history periods of up to 31 days.
  static const Duration maxPeriod = Duration(days: 31);

  /// Groups readings by metric and keeps the most recent one, in the order
  /// of [MonitoredMetric].
  static List<MetricReading> latestByMetric(List<Measurement> measurements) {
    final groups = <String, List<Measurement>>{};
    for (final m in measurements) {
      groups.putIfAbsent(m.rawMetric, () => []).add(m);
    }
    final readings = groups.values.map((items) {
      final sorted = [...items]..sort(compareNewestFirst);
      return MetricReading(latest: sorted.first, samples: items.length);
    }).toList();
    readings.sort((a, b) {
      final order = a.latest.metric.index.compareTo(b.latest.metric.index);
      return order != 0 ? order : a.latest.rawMetric.compareTo(b.latest.rawMetric);
    });
    return readings;
  }

  static int compareNewestFirst(Measurement a, Measurement b) {
    final left = a.measuredAt;
    final right = b.measuredAt;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    final byTime = right.compareTo(left);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  }

  /// Numeric metrics present in the readings, in the order of [MonitoredMetric].
  static List<MonitoredMetric> chartMetrics(List<Measurement> points) =>
      points.where((p) => p.isNumeric).map((p) => p.metric).toSet().toList()
        ..sort((a, b) => a.index.compareTo(b.index));

  /// Readings of [metric] inside [window], anchored to the most recent real
  /// timestamp (not the device clock), sorted ascending for charting.
  static List<Measurement> series(List<Measurement> points, MonitoredMetric metric, TelemetryWindow window) {
    final dated = points.where((p) => p.metric == metric && p.isNumeric && p.measuredAt != null).toList()
      ..sort((a, b) => a.measuredAt!.compareTo(b.measuredAt!));
    if (dated.isEmpty) return const [];
    final start = dated.last.measuredAt!.subtract(window.duration);
    return dated.where((p) => !p.measuredAt!.isBefore(start)).toList(growable: false);
  }

  /// A window is offered only when the real data spans more than the
  /// previous (smaller) window, so options always change what is displayed.
  static List<TelemetryWindow> availableWindows(List<Measurement> points, MonitoredMetric metric) {
    final dated = points
        .where((p) => p.metric == metric && p.isNumeric && p.measuredAt != null)
        .map((p) => p.measuredAt!)
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

  /// Readings evaluated as warning or critical, newest first.
  static List<Measurement> deviations(List<Measurement> points) =>
      points.where((p) => p.state.isDeviation).toList()..sort(compareNewestFirst);

  static List<Measurement> newestFirst(List<Measurement> points) => [...points]..sort(compareNewestFirst);

  /// Adds [incoming] readings to [current] (by id) and drops the ones older
  /// than [since], so live polling only downloads the latest minutes.
  static List<Measurement> merge(List<Measurement> current, List<Measurement> incoming, DateTime since) {
    final byId = <int, Measurement>{for (final m in current) m.id: m};
    for (final m in incoming) {
      byId[m.id] = m;
    }
    return byId.values.where((m) => m.measuredAt == null || !m.measuredAt!.isBefore(since)).toList()
      ..sort(compareNewestFirst);
  }
}

abstract interface class TelemetryRepository {
  Future<DeviceConnection> getConnection(LaboratoryId laboratoryId, TelemetryTarget target);
  Future<List<Measurement>> getMeasurements(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  });

  /// Null when no profile was configured yet.
  Future<EnvironmentalProfile?> getProfile(LaboratoryId laboratoryId, TelemetryTarget target);
  Future<List<ActuationEvent>> getActuationEvents(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  });
}
