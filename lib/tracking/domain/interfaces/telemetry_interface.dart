import '../../../common/domain/value_objects.dart';
import '../entities/actuation_event.dart';
import '../entities/device_connection.dart';
import '../entities/environmental_profile.dart';
import '../entities/measurement.dart';
import '../entities/telemetry_target.dart';

/// Contract of the telemetry repository: what can be read about the devices
/// of a laboratory, not how. Implemented by the infrastructure layer.
abstract interface class TelemetryInterface {
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
