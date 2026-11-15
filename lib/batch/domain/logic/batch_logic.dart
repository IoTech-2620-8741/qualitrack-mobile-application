import '../../../common/domain/failure.dart';
import '../entities/production_batch.dart';

/// Business rules of Product Batch Management. Pure Dart: the facade applies
/// them on top of the repository.
mixin BatchLogic {
  /// Newest start date first; batches started the same day, newest id first.
  List<ProductionBatch> sortNewestFirst(List<ProductionBatch> batches) =>
      [...batches]..sort((a, b) {
        final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });

  /// The batch routes depend on its environment and product, so a batch is
  /// looked up in the laboratory list first (notices and alerts only carry
  /// the batch id). A batch without environment cannot be reached.
  ProductionBatch findBatch(List<ProductionBatch> batches, int batchId) {
    for (final batch in batches) {
      if (batch.id == batchId && batch.environmentId != null) return batch;
    }
    throw const NotFoundFailure(code: 'BATCH_NOT_FOUND');
  }

  /// Releasing a batch requires the quality notes.
  String requireReleaseNotes(String notes) {
    final text = notes.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'RELEASE_NOTES_REQUIRED');
    return text;
  }

  /// Rejecting a batch requires a reason.
  String requireRejectionReason(String reason) {
    final text = reason.trim();
    if (text.isEmpty) throw const BadRequestFailure(code: 'REJECTION_REASON_REQUIRED');
    return text;
  }
}
