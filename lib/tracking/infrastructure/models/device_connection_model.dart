import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/device_connection.dart';

/// `DeviceTelemetryStatusResource {deviceId, connectionStatus, lastCommunicationAt, expectedPeriodSeconds}`.
class DeviceConnectionModel extends DeviceConnection {
  const DeviceConnectionModel({
    required super.deviceId,
    required super.status,
    super.lastCommunicationAt,
    super.expectedPeriodSeconds,
  });

  factory DeviceConnectionModel.fromJson(Map<String, dynamic> json) => DeviceConnectionModel(
    deviceId: Json.requireInt(json, 'deviceId'),
    status: ConnectionStatus.fromCode(Json.optString(json, 'connectionStatus')),
    lastCommunicationAt: Json.optDateTime(json, 'lastCommunicationAt'),
    expectedPeriodSeconds: Json.optInt(json, 'expectedPeriodSeconds'),
  );
}
