import '../entities/measurement.dart';
import '../entities/metric_reading.dart';
import '../entities/monitored_metric.dart';
import '../entities/telemetry_window.dart';

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
