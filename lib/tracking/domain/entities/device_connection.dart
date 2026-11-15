import 'package:equatable/equatable.dart';

import 'connection_status.dart';

/// `DeviceTelemetryStatusResource`.
class DeviceConnection extends Equatable {
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

  /// Null when the backend did not report a known status.
  bool? get reachable => status == ConnectionStatus.unknown ? null : isConnected;

  @override
  List<Object?> get props => [deviceId, status, lastCommunicationAt, expectedPeriodSeconds];
}
