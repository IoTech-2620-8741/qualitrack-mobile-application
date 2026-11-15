import 'package:equatable/equatable.dart';

import '../../../../common/presentation/remote_state.dart';
import '../../../domain/entities/batch_status.dart';
import '../../../domain/entities/batch_summary.dart';
import '../../../domain/entities/production_batch.dart';

enum BatchFilter { all, pending, inProgress, released, rejected }

final class BatchListState extends Equatable {
  const BatchListState({
    this.remote = const RemoteState(),
    this.filter = BatchFilter.all,
    this.query = '',
    this.clearCount = 0,
  });

  final RemoteState<List<ProductionBatch>> remote;
  final BatchFilter filter;
  final String query;

  /// Times the filters were cleared; the search field starts empty again when it changes.
  final int clearCount;

  /// Whether the status or the search query hides batches.
  bool get filtered => filter != BatchFilter.all || query.trim().isNotEmpty;

  BatchSummary get summary => BatchSummary.of(remote.data ?? const []);

  List<ProductionBatch> get visible => (remote.data ?? const <ProductionBatch>[])
      .where((b) => b.matches(query))
      .where((b) => switch (filter) {
        BatchFilter.all => true,
        BatchFilter.pending => b.status == BatchStatus.pending,
        BatchFilter.inProgress => b.status == BatchStatus.inProgress,
        BatchFilter.released => b.status == BatchStatus.released,
        BatchFilter.rejected => b.status == BatchStatus.rejected,
      })
      .toList(growable: false);

  BatchListState copyWith({
    RemoteState<List<ProductionBatch>>? remote,
    BatchFilter? filter,
    String? query,
    int? clearCount,
  }) => BatchListState(
    remote: remote ?? this.remote,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    clearCount: clearCount ?? this.clearCount,
  );

  @override
  List<Object?> get props => [remote, filter, query, clearCount];
}
