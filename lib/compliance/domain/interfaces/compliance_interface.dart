import '../../../common/domain/value_objects.dart';
import '../entities/compliance_event.dart';
import '../entities/deviation_alert.dart';

/// Contract of the alerts repository: what can be done with the deviation
/// alerts and compliance events, not how. Implemented by the infrastructure
/// layer.
abstract interface class ComplianceInterface {
  Future<List<DeviationAlert>> getEnvironmentAlerts(LaboratoryId laboratoryId, int environmentId);
  Future<DeviationAlert> getAlert(int alertId);
  Future<DeviationAlert> acknowledge(int alertId);
  Future<DeviationAlert> resolve(int alertId, String resolutionNotes);
  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId);
  Future<List<ComplianceEvent>> getBatchEvents(int batchId);
}
