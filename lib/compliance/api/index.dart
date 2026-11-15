/// Public entry point of the Compliance & Alerting context. Other bounded
/// contexts read alerts and compliance events through [ComplianceApi] and never
/// import the domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/compliance_facade_service.dart';
import '../domain/entities/compliance_event.dart';
import '../domain/entities/deviation_alert.dart';

export '../domain/entities/alert_origin.dart';
export '../domain/entities/alert_severity.dart';
export '../domain/entities/alert_status.dart';
export '../domain/entities/alert_summary.dart';
export '../domain/entities/compliance_event.dart';
export '../domain/entities/deviation_alert.dart';
export '../domain/entities/related_actuation.dart';

class ComplianceApi {
  const ComplianceApi(this._complianceService);

  final ComplianceFacadeService _complianceService;

  /// Alerts of the given environments, open critical alerts first.
  Future<List<DeviationAlert>> getLaboratoryAlerts(LaboratoryId laboratoryId, Iterable<int> environmentIds) =>
      _complianceService.getLaboratoryAlerts(laboratoryId, environmentIds);

  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId) =>
      _complianceService.getEquipmentEvents(laboratoryId, equipmentId);

  Future<List<ComplianceEvent>> getBatchEvents(int batchId) => _complianceService.getBatchEvents(batchId);
}
