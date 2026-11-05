import 'dart:convert';

import 'package:qualitrack_mobile/batch/domain/entities/batch_status.dart';
import 'package:qualitrack_mobile/batch/domain/entities/production_batch.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_origin.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_severity.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_status.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/deviation_alert.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/equipment.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/equipment_status.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/iot_device_type.dart';
import 'package:qualitrack_mobile/iam/domain/entities/access_token.dart';
import 'package:qualitrack_mobile/iam/domain/entities/user_role.dart';
import 'package:qualitrack_mobile/iam/domain/entities/user_session.dart';
import 'package:qualitrack_mobile/inventory/domain/entities/inventory_material.dart';
import 'package:qualitrack_mobile/laboratory/domain/entities/environment_usage.dart';
import 'package:qualitrack_mobile/laboratory/domain/entities/lab_environment.dart';
import 'package:qualitrack_mobile/common/domain/value_objects.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_state.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/measurement.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/monitored_metric.dart';

/// Test-only fixtures. Production code never uses hardcoded data.
String fakeJwt({required DateTime expiresAt}) {
  String part(Map<String, Object?> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = expiresAt.millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256'})}.${part({'sub': 'qa@lab.test', 'exp': exp})}.signature';
}

UserSession sessionFixture({
  List<UserRole> roles = const [UserRole.qaManager],
  int? laboratoryId = 7,
  DateTime? expiresAt,
  bool passwordChangeRequired = false,
}) => UserSession(
  userId: 42,
  username: 'qa@lab.test',
  roles: roles,
  laboratoryId: LaboratoryId.tryCreate(laboratoryId),
  passwordChangeRequired: passwordChangeRequired,
  token: AccessToken.fromJwt(fakeJwt(expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 1)))),
);

const LabEnvironment storage = LabEnvironment(
  id: 3,
  code: 'ALM-01',
  name: 'Cold storage',
  usage: EnvironmentUsage.productStorage,
);

const LabEnvironment production = LabEnvironment(id: 4, code: 'PRD-01', name: 'Production line');

DeviationAlert alertFixture({
  int id = 1,
  int equipmentId = 10,
  int environmentId = 3,
  AlertStatus status = AlertStatus.unresolved,
  AlertSeverity severity = AlertSeverity.critical,
  DateTime? timestamp,
}) => DeviationAlert(
  id: id,
  environmentId: environmentId,
  origin: AlertOrigin.container,
  equipmentId: equipmentId,
  parameterName: 'TEMPERATURE',
  recordedValue: 38.6,
  thresholdValue: 30,
  unit: '°C',
  status: status,
  severity: severity,
  timestamp: timestamp ?? DateTime.utc(2026, 6, 14, 15, 50),
);

Equipment equipmentFixture({
  int id = 10,
  String name = 'Stability Chamber',
  int? environmentId = 3,
  IotDeviceType? deviceType = IotDeviceType.containerMonitor,
}) => Equipment(
  id: id,
  laboratoryId: 7,
  environmentId: environmentId,
  name: name,
  type: 'Chamber',
  model: 'SC-1',
  serialNumber: 'SN-$id',
  status: EquipmentStatus.operational,
  rawStatus: 'OPERATIONAL',
  deviceType: deviceType,
  sensorExternalId: 'ESP32-$id',
);

ProductionBatch batchFixture({
  int id = 3,
  BatchStatus status = BatchStatus.pending,
  String batchNumber = 'LOT-2026-123',
  int? environmentId = 4,
}) => ProductionBatch(
  id: id,
  labId: 7,
  environmentId: environmentId,
  productId: 1,
  productName: 'Ibuprofen 400mg',
  batchNumber: batchNumber,
  quantity: 2,
  unit: 'units',
  status: status,
  startDate: '2026-09-04',
  notes: 'Pending QA approval',
);

Measurement measurementFixture({
  int id = 1,
  int deviceId = 10,
  MonitoredMetric metric = MonitoredMetric.temperature,
  double? value = 6.5,
  EnvironmentalState state = EnvironmentalState.normal,
  DateTime? measuredAt,
}) => Measurement(
  id: id,
  deviceId: deviceId,
  environmentId: 3,
  metric: metric,
  rawMetric: metric.code,
  value: value,
  unit: '°C',
  state: state,
  measuredAt: measuredAt ?? DateTime.utc(2026, 6, 14, 12),
);

InventoryMaterial materialFixture({
  int id = 1,
  int environmentId = 3,
  String name = 'Hierro',
  double usable = 3,
  String? stockStatus = 'LOW',
}) => InventoryMaterial(
  id: id,
  laboratoryId: 7,
  environmentId: environmentId,
  code: 'FE-$id',
  name: name,
  unit: 'g',
  minimumStock: 5,
  usableStock: usable,
  physicalStock: 10,
  stockStatus: stockStatus,
);

const Map<String, dynamic> alertJson = {
  'id': 2,
  'laboratoryId': 7,
  'environmentId': 3,
  'origin': 'CONTAINER',
  'equipmentId': 10,
  'batchId': null,
  'parameterName': 'TEMPERATURE',
  'recordedValue': 9.4,
  'thresholdValue': 8.0,
  'unit': '°C',
  'timestamp': '2026-09-03T17:01:24Z',
  'severity': 'CRITICAL',
  'status': 'UNRESOLVED',
  'deviationCount': 3,
  'lastDetectedAt': '2026-09-03T17:21:24Z',
  'normalizedAt': null,
  'acknowledgedBy': null,
  'acknowledgedAt': null,
  'resolvedBy': null,
  'resolvedAt': null,
  'resolutionNotes': null,
  'relatedActuations': [
    {'id': 5, 'action': 'COOLING_ON', 'triggerState': 'CRITICAL', 'result': 'EXECUTED', 'occurredAt': '2026-09-03T17:01:30Z'},
  ],
};
