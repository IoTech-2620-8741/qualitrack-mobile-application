import '../../../shared/infrastructure/http/api_client.dart';
import '../../../shared/infrastructure/http/json_utils.dart';
import '../../domain/entities/production_batch.dart';
import '../models/batch_traceability_model.dart';
import '../models/production_batch_model.dart';

/// Talks to the batch endpoints of the QualiTrack REST API.
class BatchRemoteDataProvider {
  const BatchRemoteDataProvider(this._client);

  final ApiClient _client;

  String _batch(int labId, ProductionBatch batch) =>
      '/laboratories/$labId/environments/${batch.environmentId}/products/${batch.productId}/batches/${batch.id}';

  Future<List<ProductionBatchModel>> getByLab(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/batches')).map(ProductionBatchModel.fromJson).toList();

  Future<BatchTraceabilityModel> getTraceability(int labId, ProductionBatch batch) async =>
      BatchTraceabilityModel.fromJson(Json.asMap(await _client.get('${_batch(labId, batch)}/traceability')));

  Future<void> release(int labId, ProductionBatch batch, String releaseDate, String notes) =>
      _client.post('${_batch(labId, batch)}/releases', body: {'releaseDate': releaseDate, 'notes': notes});

  Future<void> reject(int labId, ProductionBatch batch, String rejectionDate, String reason) =>
      _client.post('${_batch(labId, batch)}/rejections', body: {'rejectionDate': rejectionDate, 'reason': reason});
}
