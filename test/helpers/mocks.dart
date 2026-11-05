import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/interfaces/batch_interface.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/equipment/domain/equipment.dart';
import 'package:qualitrack_mobile/iam/domain/iam_repositories.dart';
import 'package:qualitrack_mobile/inventory/domain/inventory.dart';
import 'package:qualitrack_mobile/laboratory/domain/laboratory.dart';
import 'package:qualitrack_mobile/profile/domain/interfaces/profile_interface.dart';
import 'package:qualitrack_mobile/reporting/domain/reporting.dart';
import 'package:qualitrack_mobile/common/infrastructure/http/api_client.dart';
import 'package:qualitrack_mobile/common/infrastructure/storage/secure_key_value_store.dart';
import 'package:qualitrack_mobile/subscription/domain/interfaces/subscription_interface.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockLaboratoryRepository extends Mock implements LaboratoryRepository {}

class MockComplianceRepository extends Mock implements ComplianceRepository {}

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockBatchRepository extends Mock implements BatchInterface {}

class MockEquipmentRepository extends Mock implements EquipmentRepository {}

class MockTelemetryRepository extends Mock implements TelemetryRepository {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockSubscriptionRepository extends Mock implements SubscriptionInterface {}

class MockProfileRepository extends Mock implements ProfileInterface {}

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
