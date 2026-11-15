import '../../../common/domain/value_objects.dart';
import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/actuation_event.dart';
import '../../domain/entities/device_connection.dart';
import '../../domain/entities/environmental_profile.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/telemetry_target.dart';
import '../../domain/interfaces/telemetry_interface.dart';
import '../data_sources/telemetry_remote_data_provider.dart';

/// Implements [TelemetryInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider.
class TelemetryRepository implements TelemetryInterface {
  const TelemetryRepository({required TelemetryRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final TelemetryRemoteDataProvider _remote;

  @override
  Future<DeviceConnection> getConnection(LaboratoryId laboratoryId, TelemetryTarget target) =>
      _remote.getConnection(laboratoryId.value, target.environmentId, target.deviceId);

  /// Same wire format as Web: `Date.toISOString()` (UTC, milliseconds, `Z`).
  @override
  Future<List<Measurement>> getMeasurements(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) => _remote.getMeasurements(laboratoryId.value, target, from: toIsoMillis(from), to: toIsoMillis(to));

  @override
  Future<EnvironmentalProfile?> getProfile(LaboratoryId laboratoryId, TelemetryTarget target) =>
      nullOnNotFound(() => _remote.getProfile(laboratoryId.value, target));

  @override
  Future<List<ActuationEvent>> getActuationEvents(
    LaboratoryId laboratoryId,
    TelemetryTarget target, {
    required DateTime from,
    required DateTime to,
  }) => _remote.getActuationEvents(laboratoryId.value, target, from: toIsoMillis(from), to: toIsoMillis(to));
}
