import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/equipment/domain/equipment.dart';
import 'package:qualitrack_mobile/iam/domain/iam_repositories.dart';
import 'package:qualitrack_mobile/shared/infrastructure/http/api_client.dart';
import 'package:qualitrack_mobile/shared/infrastructure/storage/secure_key_value_store.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockComplianceRepository extends Mock implements ComplianceRepository {}

class MockBatchRepository extends Mock implements BatchRepository {}

class MockEquipmentRepository extends Mock implements EquipmentRepository {}

class MockTelemetryRepository extends Mock implements TelemetryRepository {}

class MockApiClient extends Mock implements ApiClient {}

/// In-memory replacement for the platform keystore.
class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
