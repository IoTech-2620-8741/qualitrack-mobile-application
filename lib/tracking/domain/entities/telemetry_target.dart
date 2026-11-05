import 'package:equatable/equatable.dart';

/// An IoT device whose telemetry is read: the environmental device of an
/// environment or a container monitor located in it.
class TelemetryTarget extends Equatable {
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
