import '../../shared/domain/failure.dart';
import '../domain/compliance.dart';

/// Laboratory-wide alerts. The backend exposes alerts per equipment only, so
/// they are aggregated with bounded concurrency (same as the Web dashboard).
class GetLaboratoryAlerts {
  const GetLaboratoryAlerts(this._repository);

  final ComplianceRepository _repository;

  static const int maxParallel = 4;

  Future<List<DeviationAlert>> call(List<int> equipmentIds) async {
    final byId = <int, DeviationAlert>{};
    for (var i = 0; i < equipmentIds.length; i += maxParallel) {
      final chunk = equipmentIds.skip(i).take(maxParallel).toList();
      final groups = await Future.wait(chunk.map(_repository.getEquipmentAlerts));
      for (var j = 0; j < chunk.length; j++) {
        for (final alert in groups[j].where((a) => a.equipmentId == chunk[j])) {
          byId[alert.id] = alert;
        }
      }
    }
    return byId.values.toList()..sort(DeviationAlert.compareByPriority);
  }
}

class GetBatchAlerts {
  const GetBatchAlerts(this._repository);

  final ComplianceRepository _repository;

  Future<List<DeviationAlert>> call(int batchId) async {
    final alerts = await _repository.getBatchAlerts(batchId);
    return [...alerts]..sort(DeviationAlert.compareByPriority);
  }
}

class GetAlertDetail {
  const GetAlertDetail(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call(int alertId) => _repository.getAlert(alertId);
}

/// Command: UNRESOLVED → ACKNOWLEDGED. `performedBy` must be the signed-in
/// user; the backend verifies it.
class AcknowledgeAlert {
  const AcknowledgeAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call({required int alertId, required int performedBy}) =>
      _repository.acknowledge(alertId: alertId, performedBy: performedBy);
}

/// Command: → RESOLVED with mandatory resolution notes (backend rule).
class ResolveAlert {
  const ResolveAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call({
    required int alertId,
    required int performedBy,
    required String resolutionNotes,
  }) {
    final notes = resolutionNotes.trim();
    if (notes.isEmpty) {
      throw const BadRequestFailure(code: 'RESOLUTION_NOTES_REQUIRED');
    }
    return _repository.resolve(alertId: alertId, performedBy: performedBy, resolutionNotes: notes);
  }
}

class GetEquipmentComplianceEvents {
  const GetEquipmentComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(int equipmentId) async =>
      _newestFirst(await _repository.getEquipmentEvents(equipmentId));
}

class GetBatchComplianceEvents {
  const GetBatchComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(int batchId) async =>
      _newestFirst(await _repository.getBatchEvents(batchId));
}

List<ComplianceEvent> _newestFirst(List<ComplianceEvent> events) => [...events]
  ..sort((a, b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
