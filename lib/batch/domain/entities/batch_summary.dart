import 'package:equatable/equatable.dart';

import 'batch_status.dart';
import 'production_batch.dart';

class BatchSummary extends Equatable {
  const BatchSummary({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.released,
    required this.rejected,
  });

  factory BatchSummary.of(List<ProductionBatch> batches) => BatchSummary(
    total: batches.length,
    pending: batches.where((b) => b.status == BatchStatus.pending).length,
    inProgress: batches.where((b) => b.status == BatchStatus.inProgress).length,
    released: batches.where((b) => b.status == BatchStatus.released).length,
    rejected: batches.where((b) => b.status == BatchStatus.rejected).length,
  );

  final int total;
  final int pending;
  final int inProgress;
  final int released;
  final int rejected;

  @override
  List<Object?> get props => [total, pending, inProgress, released, rejected];
}
