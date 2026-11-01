import '../../../shared/domain/value_objects.dart';
import '../../domain/entities/batch_traceability.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/interfaces/batch_interface.dart';
import '../data_sources/batch_remote_data_provider.dart';

/// Implements [BatchInterface] with the REST API. There is no offline cache:
/// every read goes to the remote data provider.
class BatchRepository implements BatchInterface {
  const BatchRepository({required BatchRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final BatchRemoteDataProvider _remote;

  @override
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId) async {
    final batches = await _remote.getByLab(laboratoryId.value);
    return List<ProductionBatch>.of(batches.where((b) => b.labId == laboratoryId.value), growable: false);
  }

  @override
  Future<BatchTraceability> getTraceability(LaboratoryId laboratoryId, ProductionBatch batch) =>
      _remote.getTraceability(laboratoryId.value, batch);

  @override
  Future<void> release(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String releaseDate,
    required String notes,
  }) => _remote.release(laboratoryId.value, batch, releaseDate, notes);

  @override
  Future<void> reject(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String rejectionDate,
    required String reason,
  }) => _remote.reject(laboratoryId.value, batch, rejectionDate, reason);
}
