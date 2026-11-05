import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/interfaces/batch_interface.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_facade_service.dart';
import 'package:qualitrack_mobile/compliance/domain/interfaces/compliance_interface.dart';
import 'package:qualitrack_mobile/equipment/domain/interfaces/equipment_interface.dart';
import 'package:qualitrack_mobile/iam/domain/interfaces/iam_interface.dart';
import 'package:qualitrack_mobile/inventory/domain/interfaces/inventory_interface.dart';
import 'package:qualitrack_mobile/laboratory/domain/interfaces/laboratory_interface.dart';
import 'package:qualitrack_mobile/profile/domain/interfaces/profile_interface.dart';
import 'package:qualitrack_mobile/reporting/domain/reporting.dart';
import 'package:qualitrack_mobile/common/infrastructure/http/api_client.dart';
import 'package:qualitrack_mobile/common/infrastructure/storage/secure_key_value_store.dart';
import 'package:qualitrack_mobile/subscription/domain/interfaces/subscription_interface.dart';
import 'package:qualitrack_mobile/tracking/domain/interfaces/telemetry_interface.dart';

class MockIamRepository extends Mock implements IamInterface {}

class MockLaboratoryRepository extends Mock implements LaboratoryInterface {}

class MockComplianceRepository extends Mock implements ComplianceInterface {}

class MockBatchRepository extends Mock implements BatchInterface {}

class MockEquipmentRepository extends Mock implements EquipmentInterface {}

class MockTelemetryRepository extends Mock implements TelemetryInterface {}

class MockInventoryRepository extends Mock implements InventoryInterface {}

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockSubscriptionRepository extends Mock implements SubscriptionInterface {}

class MockProfileRepository extends Mock implements ProfileInterface {}

/// Facade over the given repository; an empty mock when none is given.
ComplianceFacadeService complianceFacade([ComplianceInterface? repository]) =>
    ComplianceFacadeService(repository: repository ?? MockComplianceRepository());

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
