import '../../../../common/domain/failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/domain/value_objects.dart';
import '../../../application/batch_facade_service.dart';
import 'batch_list_event.dart';
import 'batch_list_state.dart';

class BatchListBloc extends Bloc<BatchListEvent, BatchListState> {
  BatchListBloc({required BatchFacadeService batchService, required LaboratoryId Function() laboratoryId})
    : _batchService = batchService,
      _laboratoryId = laboratoryId,
      super(const BatchListState()) {
    on<BatchListRequested>(_onRequested);
    on<BatchListFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
    on<BatchListQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<BatchListFiltersCleared>(
      (e, emit) => emit(state.copyWith(filter: BatchFilter.all, query: '', clearCount: state.clearCount + 1)),
    );
  }

  final BatchFacadeService _batchService;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BatchListRequested event, Emitter<BatchListState> emit) async {
    final current = state.remote;
    emit(state.copyWith(
      remote: event.refresh && current.hasData ? current.refreshingState() : current.loading(),
    ));
    try {
      final batches = await _batchService.getBatches(_laboratoryId());
      emit(state.copyWith(remote: state.remote.success(batches, empty: batches.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }
}
