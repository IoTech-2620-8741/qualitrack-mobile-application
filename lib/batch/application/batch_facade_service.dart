import '../../common/domain/value_objects.dart';
import '../domain/entities/batch_traceability.dart';
import '../domain/entities/production_batch.dart';
import '../domain/interfaces/batch_interface.dart';
import '../domain/logic/batch_logic.dart';
import '../domain/logic/iso_date.dart';

/// Use cases of Product Batch Management exposed to the presentation layer.
/// It only orchestrates: the rules live in [BatchLogic] and the data access
/// behind [BatchInterface].
class BatchFacadeService with BatchLogic {
  const BatchFacadeService({required BatchInterface repository}) : _repository = repository;

  final BatchInterface _repository;

  /// Batches of the laboratory, newest start date first.
  Future<List<ProductionBatch>> getBatches(LaboratoryId laboratoryId) async =>
      sortNewestFirst(await _repository.getByLaboratory(laboratoryId));

  /// Traceability of a batch of the laboratory.
  Future<BatchTraceability> getTraceability(LaboratoryId laboratoryId, int batchId) async {
    final batch = findBatch(await _repository.getByLaboratory(laboratoryId), batchId);
    return _repository.getTraceability(laboratoryId, batch);
  }

  /// Command: release a batch that meets its specifications. The backend signs
  /// the decision (user, time and SHA-256 hash) and notifies the staff.
  Future<void> release(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required DateTime releaseDate,
    required String notes,
  }) {
    final text = requireReleaseNotes(notes);
    return _repository.release(laboratoryId, batch, releaseDate: isoDate(releaseDate), notes: text);
  }

  /// Command: reject a batch with a mandatory reason.
  Future<void> reject(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required DateTime rejectionDate,
    required String reason,
  }) {
    final text = requireRejectionReason(reason);
    return _repository.reject(laboratoryId, batch, rejectionDate: isoDate(rejectionDate), reason: text);
  }
}
