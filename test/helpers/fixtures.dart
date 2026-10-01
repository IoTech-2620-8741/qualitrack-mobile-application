import 'dart:convert';

import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/equipment/domain/equipment.dart';
import 'package:qualitrack_mobile/iam/domain/access_token.dart';
import 'package:qualitrack_mobile/iam/domain/user_role.dart';
import 'package:qualitrack_mobile/iam/domain/user_session.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';

/// Test-only fixtures. Production code never uses hardcoded data.
String fakeJwt({required DateTime expiresAt}) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = expiresAt.millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256'})}.${part({'sub': 'qa@lab.test', 'exp': exp})}.signature';
}

UserSession sessionFixture({
  List<UserRole> roles = const [UserRole.qaManager],
  int? laboratoryId = 7,
  DateTime? expiresAt,
}) => UserSession(
  userId: 42,
  username: 'qa@lab.test',
  roles: roles,
  laboratoryId: LaboratoryId.tryCreate(laboratoryId),
  token: AccessToken.fromJwt(
    fakeJwt(expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 1))),
  ),
);

DeviationAlert alertFixture({
  int id = 1,
  int equipmentId = 10,
  AlertStatus status = AlertStatus.unresolved,
  AlertSeverity severity = AlertSeverity.critical,
  DateTime? timestamp,
}) => DeviationAlert(
  id: id,
  equipmentId: equipmentId,
  parameterName: 'Temperature',
  recordedValue: 38.6,
  thresholdValue: 30,
  unit: '°C',
  status: status,
  severity: severity,
  timestamp: timestamp ?? DateTime.utc(2026, 6, 14, 15, 50),
);

Equipment equipmentFixture({int id = 10, String name = 'Stability Chamber'}) => Equipment(
  id: id,
  laboratoryId: 7,
  name: name,
  type: 'Chamber',
  model: 'SC-1',
  serialNumber: 'SN-$id',
  status: EquipmentStatus.operational,
  rawStatus: 'OPERATIONAL',
  sensorExternalId: 'ESP32-$id',
);

ProductionBatch batchFixture({
  int id = 3,
  BatchStatus status = BatchStatus.pending,
  String batchNumber = 'LOT-2026-123',
}) => ProductionBatch(
  id: id,
  labId: 7,
  productId: 1,
  productName: 'Ibuprofen 400mg',
  batchNumber: batchNumber,
  quantity: 2,
  unit: 'units',
  status: status,
  startDate: '2026-09-04',
  notes: 'Pending QA approval',
);

const Map<String, dynamic> alertJson = {
  'id': 2,
  'equipmentId': 1,
  'batchId': null,
  'parameterName': 'Calidad de Aire',
  'recordedValue': 40.0,
  'thresholdValue': 30.0,
  'unit': 'telemetry',
  'timestamp': '2026-09-03T17:01:24Z',
  'severity': 'CRITICAL',
  'status': 'UNRESOLVED',
  'acknowledgedBy': null,
  'resolvedBy': null,
  'resolutionNotes': null,
};
