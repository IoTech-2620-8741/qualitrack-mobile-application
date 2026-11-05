import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../compliance/application/compliance_queries.dart';
import '../../../../compliance/domain/compliance.dart';
import '../../../../laboratory/application/laboratory_queries.dart';
import '../../../../reporting/application/reporting_queries.dart';
import '../../../../reporting/domain/reporting.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/domain/value_objects.dart';
import '../../../../shared/presentation/section.dart';
import '../../../application/batch_facade_service.dart';
import '../../../domain/entities/production_batch.dart';
import 'batch_detail_event.dart';
import 'batch_detail_state.dart';

class BatchDetailBloc extends Bloc<BatchDetailEvent, BatchDetailState> {
  BatchDetailBloc({
    required this.batchId,
    required BatchFacadeService batchService,
    required GetBatchComplianceEvents getEvents,
    required GetBatchAuditLogs getAuditLogs,
    required GetUserDirectory getUserDirectory,
    required LaboratoryId Function() laboratoryId,
  }) : _batchService = batchService,
       _getEvents = getEvents,
       _getAuditLogs = getAuditLogs,
       _getUserDirectory = getUserDirectory,
       _laboratoryId = laboratoryId,
       super(const BatchDetailState()) {
    on<BatchDetailRequested>(_onRequested);
    on<BatchReleaseSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.release,
        (batch) => _batchService.release(_laboratoryId(), batch, releaseDate: e.date, notes: e.notes),
      ),
    );
    on<BatchRejectSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.reject,
        (batch) => _batchService.reject(_laboratoryId(), batch, rejectionDate: e.date, reason: e.reason),
      ),
    );
  }

  final int batchId;
  final BatchFacadeService _batchService;
  final GetBatchComplianceEvents _getEvents;
  final GetBatchAuditLogs _getAuditLogs;
  final GetUserDirectory _getUserDirectory;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BatchDetailRequested event, Emitter<BatchDetailState> emit) async {
    final current = state.detail;
    emit(state.copyWith(detail: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      emit(state.copyWith(detail: state.detail.success(await _load())));
    } catch (error) {
      emit(state.copyWith(detail: state.detail.failed(Failure.from(error))));
    }
  }

  Future<BatchDetail> _load() async {
    final laboratoryId = _laboratoryId();
    final traceability = await _batchService.getTraceability(laboratoryId, batchId);
    final sections = await Future.wait<Object>([
      Section.load(() => _getEvents(batchId)),
      Section.load(() => _getAuditLogs(batchId)),
      _people(laboratoryId),
    ]);
    return BatchDetail(
      traceability: traceability,
      events: sections[0] as Section<ComplianceEvent>,
      auditLogs: sections[1] as Section<AuditLogEntry>,
      people: sections[2] as Map<int, String>,
    );
  }

  /// Names are a convenience: ids are shown when the staff cannot be read.
  Future<Map<int, String>> _people(LaboratoryId laboratoryId) async {
    try {
      return await _getUserDirectory(laboratoryId);
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return const {};
    }
  }

  Future<void> _run(
    Emitter<BatchDetailState> emit,
    BatchReviewAction action,
    Future<void> Function(ProductionBatch batch) command,
  ) async {
    final current = state.detail.data;
    if (state.submitting || current == null) return;
    emit(state.copyWith(actionStatus: BatchActionStatus.submitting, lastAction: action, clearActionFailure: true));
    try {
      await command(current.batch);
      // The decision changes the traceability, the audit log and the events.
      emit(state.copyWith(detail: state.detail.success(await _load()), actionStatus: BatchActionStatus.success));
    } catch (error) {
      emit(state.copyWith(actionStatus: BatchActionStatus.failure, actionFailure: Failure.from(error)));
    }
  }
}
