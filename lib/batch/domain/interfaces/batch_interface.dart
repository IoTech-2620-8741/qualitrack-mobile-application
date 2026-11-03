import '../../../shared/domain/value_objects.dart';
import '../entities/batch_traceability.dart';
import '../entities/production_batch.dart';

/// Contract of the batch repository: what can be done with the batches of a
/// laboratory, not how. Implemented by the infrastructure layer.
abstract interface class BatchInterface {
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId);
  Future<BatchTraceability> getTraceability(LaboratoryId laboratoryId, ProductionBatch batch);
  Future<void> release(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String releaseDate,
    required String notes,
  });
  Future<void> reject(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String rejectionDate,
    required String reason,
  });
}
