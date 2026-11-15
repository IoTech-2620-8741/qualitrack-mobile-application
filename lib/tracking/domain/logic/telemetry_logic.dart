import '../../../common/domain/failure.dart';
import '../entities/actuation_event.dart';
import '../entities/measurement.dart';
import 'telemetry_analysis.dart';

/// Business rules of Tracking & Telemetry. Pure Dart: the facade applies them
/// on top of the repository.
mixin TelemetryLogic {
  /// The backend accepts history periods of up to 31 days; check before calling it.
  void requireValidPeriod(DateTime from, DateTime to) {
    if (!from.isBefore(to) || to.difference(from) > TelemetryAnalysis.maxPeriod) {
      throw const BadRequestFailure(code: 'INVALID_PERIOD');
    }
  }

  /// The environment endpoint also returns readings of other devices of the
  /// environment, so only those of [deviceId] are kept, newest first.
  List<Measurement> measurementsOfDevice(List<Measurement> points, int deviceId) =>
      TelemetryAnalysis.newestFirst(points.where((p) => p.deviceId == deviceId).toList());

  /// Newest action first; undated ones go last, newest id first.
  List<ActuationEvent> sortEventsNewestFirst(List<ActuationEvent> events) => [...events]
    ..sort((a, b) {
      final left = a.occurredAt;
      final right = b.occurredAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
}
