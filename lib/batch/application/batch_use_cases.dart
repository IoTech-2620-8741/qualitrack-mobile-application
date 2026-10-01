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

class GetBatchDetail {
  const GetBatchDetail(this._repository);

  final BatchRepository _repository;

  Future<ProductionBatch> call(int batchId) => _repository.getById(batchId);
}

class GetBatchRawMaterials {
  const GetBatchRawMaterials(this._repository);

  final BatchRepository _repository;

  Future<List<RawMaterialUsage>> call(int batchId) => _repository.getRawMaterialUsage(batchId);
}

/// Formats a date as `yyyy-MM-dd`, the format used by Web and stored by the
/// batch aggregate as `endDate`.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Command: release an EXISTING batch. Only the fields required by
/// `PATCH /batches/{id}` are sent; transition rules stay in the backend.
class ReleaseExistingBatch {
  const ReleaseExistingBatch(this._repository);

  final BatchRepository _repository;

  Future<ProductionBatch> call({
    required int batchId,
    required DateTime releaseDate,
    required String notes,
  }) {
    final text = notes.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'RELEASE_NOTES_REQUIRED');
    return _repository.release(batchId: batchId, releaseDate: isoDate(releaseDate), notes: text);
  }
}

/// Command: reject an EXISTING batch with a mandatory reason.
class RejectExistingBatch {
  const RejectExistingBatch(this._repository);

  final BatchRepository _repository;

  Future<ProductionBatch> call({
    required int batchId,
    required DateTime rejectionDate,
    required String reason,
  }) {
    final text = reason.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'REJECTION_REASON_REQUIRED');
    return _repository.reject(batchId: batchId, rejectionDate: isoDate(rejectionDate), reason: text);
  }
}
