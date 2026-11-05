/// Public entry point of the Product Batch Management context. Other bounded
/// contexts (for example the Command Center) consume batches through
/// [BatchApi] and never import the domain or the infrastructure directly.
library;

import '../../shared/domain/value_objects.dart';
import '../application/batch_facade_service.dart';
import '../domain/entities/production_batch.dart';

export '../domain/entities/batch_status.dart';
export '../domain/entities/batch_summary.dart';
export '../domain/entities/production_batch.dart';
export '../presentation/widgets/batch_labels.dart';

class BatchApi {
  const BatchApi(this._batchService);

  final BatchFacadeService _batchService;

  /// Batches of the laboratory, newest start date first.
  Future<List<ProductionBatch>> getBatches(LaboratoryId laboratoryId) => _batchService.getBatches(laboratoryId);
}
