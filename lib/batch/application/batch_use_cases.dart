import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/batch.dart';

class GetBatches {
  const GetBatches(this._repository);

  final BatchRepository _repository;

  /// Newest start date first.
  Future<List<ProductionBatch>> call(LaboratoryId laboratoryId) async {
    final batches = await _repository.getByLaboratory(laboratoryId);
    return [...batches]..sort((a, b) {
      final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
  }
}

/// Traceability of a batch of the laboratory. The batch routes depend on its
/// environment and product, so the batch is looked up in the laboratory list
/// first (notices and alerts only carry the batch id).
class GetBatchTraceability {
  const GetBatchTraceability(this._repository);

  final BatchRepository _repository;

  Future<BatchTraceability> call(LaboratoryId laboratoryId, int batchId) async {
    final batch = await findBatch(_repository, laboratoryId, batchId);
    return _repository.getTraceability(laboratoryId, batch);
  }
}

Future<ProductionBatch> findBatch(BatchRepository repository, LaboratoryId laboratoryId, int batchId) async {
  for (final batch in await repository.getByLaboratory(laboratoryId)) {
    if (batch.id == batchId && batch.environmentId != null) return batch;
  }
  throw const NotFoundFailure(code: 'BATCH_NOT_FOUND');
}

/// Formats a date as `yyyy-MM-dd`, the format used by Web.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Command: release a batch that meets its specifications. The backend signs
/// the decision (user, time and SHA-256 hash) and notifies the staff.
class ReleaseBatch {
  const ReleaseBatch(this._repository);

  final BatchRepository _repository;

  Future<void> call(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required DateTime releaseDate,
    required String notes,
  }) {
    final text = notes.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'RELEASE_NOTES_REQUIRED');
    return _repository.release(laboratoryId, batch, releaseDate: isoDate(releaseDate), notes: text);
  }
}

/// Command: reject a batch with a mandatory reason.
class RejectBatch {
  const RejectBatch(this._repository);

  final BatchRepository _repository;

  Future<void> call(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required DateTime rejectionDate,
    required String reason,
  }) {
    final text = reason.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'REJECTION_REASON_REQUIRED');
    return _repository.reject(laboratoryId, batch, rejectionDate: isoDate(rejectionDate), reason: text);
  }
}
