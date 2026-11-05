/// Public entry point of the Tracking & Telemetry context. Other bounded
/// contexts read device connections through [TelemetryApi] and never import the
/// domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/telemetry_facade_service.dart';
import '../domain/entities/device_connection.dart';
import '../domain/entities/telemetry_target.dart';

export '../application/telemetry_targets.dart';
export '../domain/entities/connection_status.dart';
export '../domain/entities/device_connection.dart';
export '../domain/entities/telemetry_target.dart';

class TelemetryApi {
  const TelemetryApi(this._telemetryService);

  final TelemetryFacadeService _telemetryService;

  Future<DeviceConnection> getConnection(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _telemetryService.getConnection(laboratoryId, target);

  /// Connection status of many devices; the ones that cannot be read are absent.
  Future<Map<int, DeviceConnection>> getConnections(LaboratoryId laboratoryId, List<TelemetryTarget> targets) =>
      _telemetryService.getConnections(laboratoryId, targets);
}
