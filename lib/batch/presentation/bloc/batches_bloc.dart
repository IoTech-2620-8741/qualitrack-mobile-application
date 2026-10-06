import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/batch_use_cases.dart';
import '../../domain/batch.dart';

enum BatchFilter { all, pending, inProgress, released, rejected }

sealed class BatchesEvent extends Equatable {
  const BatchesEvent();

  @override
  List<Object?> get props => [];
}

final class BatchesRequested extends BatchesEvent {
  const BatchesRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class BatchesFilterChanged extends BatchesEvent {
  const BatchesFilterChanged(this.filter);

  final BatchFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class BatchesQueryChanged extends BatchesEvent {
  const BatchesQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class BatchesState extends Equatable {
  const BatchesState({
    this.remote = const RemoteState(),
    this.filter = BatchFilter.all,
    this.query = '',
  });

  final RemoteState<List<ProductionBatch>> remote;
  final BatchFilter filter;
  final String query;

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

  BatchesState copyWith({
    RemoteState<List<ProductionBatch>>? remote,
    BatchFilter? filter,
    String? query,
  }) => BatchesState(
    remote: remote ?? this.remote,
    filter: filter ?? this.filter,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [remote, filter, query];
}

class BatchesBloc extends Bloc<BatchesEvent, BatchesState> {
  BatchesBloc({required GetBatches getBatches, required LaboratoryId Function() laboratoryId})
    : _getBatches = getBatches,
      _laboratoryId = laboratoryId,
      super(const BatchesState()) {
    on<BatchesRequested>(_onRequested);
    on<BatchesFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
    on<BatchesQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
  }

  final GetBatches _getBatches;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BatchesRequested event, Emitter<BatchesState> emit) async {
    final current = state.remote;
    emit(state.copyWith(
      remote: event.refresh && current.hasData ? current.refreshingState() : current.loading(),
    ));
    try {
      final batches = await _getBatches(_laboratoryId());
      emit(state.copyWith(remote: state.remote.success(batches, empty: batches.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}
