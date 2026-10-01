import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../compliance/application/compliance_queries.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../reporting/application/reporting_queries.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../application/batch_use_cases.dart';
import '../../domain/batch.dart';

final class BatchDetail extends Equatable {
  const BatchDetail({
    required this.batch,
    this.rawMaterials = const Section.empty(),
    this.alerts = const Section.empty(),
    this.events = const Section.empty(),
    this.auditLogs = const Section.empty(),
  });

  final ProductionBatch batch;
  final Section<RawMaterialUsage> rawMaterials;
  final Section<DeviationAlert> alerts;
  final Section<ComplianceEvent> events;
  final Section<AuditLogEntry> auditLogs;

  BatchDetail withBatch(ProductionBatch updated) => BatchDetail(
    batch: updated,
    rawMaterials: rawMaterials,
    alerts: alerts,
    events: events,
    auditLogs: auditLogs,
  );

  @override
  List<Object?> get props => [batch, rawMaterials, alerts, events, auditLogs];
}

enum BatchReviewAction { release, reject }

enum BatchActionStatus { idle, submitting, success, failure }

sealed class BatchDetailEvent extends Equatable {
  const BatchDetailEvent();

  @override
  List<Object?> get props => [];
}

final class BatchDetailRequested extends BatchDetailEvent {
  const BatchDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class BatchReleaseSubmitted extends BatchDetailEvent {
  const BatchReleaseSubmitted({required this.date, required this.notes});

  final DateTime date;
  final String notes;

  @override
  List<Object?> get props => [date, notes];
}

final class BatchRejectSubmitted extends BatchDetailEvent {
  const BatchRejectSubmitted({required this.date, required this.reason});

  final DateTime date;
  final String reason;

  @override
  List<Object?> get props => [date, reason];
}

final class BatchDetailState extends Equatable {
  const BatchDetailState({
    this.detail = const RemoteState(),
    this.actionStatus = BatchActionStatus.idle,
    this.lastAction,
    this.actionFailure,
  });

  final RemoteState<BatchDetail> detail;
  final BatchActionStatus actionStatus;
  final BatchReviewAction? lastAction;
  final Failure? actionFailure;

  bool get submitting => actionStatus == BatchActionStatus.submitting;

  BatchDetailState copyWith({
    RemoteState<BatchDetail>? detail,
    BatchActionStatus? actionStatus,
    BatchReviewAction? lastAction,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => BatchDetailState(
    detail: detail ?? this.detail,
    actionStatus: actionStatus ?? this.actionStatus,
    lastAction: lastAction ?? this.lastAction,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [detail, actionStatus, lastAction, actionFailure];
}

class BatchDetailBloc extends Bloc<BatchDetailEvent, BatchDetailState> {
  BatchDetailBloc({
    required this.batchId,
    required GetBatchDetail getBatch,
    required GetBatchRawMaterials getRawMaterials,
    required GetBatchAlerts getAlerts,
    required GetBatchComplianceEvents getEvents,
    required GetBatchAuditLogs getAuditLogs,
    required ReleaseExistingBatch release,
    required RejectExistingBatch reject,
  }) : _getBatch = getBatch,
       _getRawMaterials = getRawMaterials,
       _getAlerts = getAlerts,
       _getEvents = getEvents,
       _getAuditLogs = getAuditLogs,
       _release = release,
       _reject = reject,
       super(const BatchDetailState()) {
    on<BatchDetailRequested>(_onRequested);
    on<BatchReleaseSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.release,
        () => _release(batchId: batchId, releaseDate: e.date, notes: e.notes),
      ),
    );
    on<BatchRejectSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.reject,
        () => _reject(batchId: batchId, rejectionDate: e.date, reason: e.reason),
      ),
    );
  }

  final int batchId;
  final GetBatchDetail _getBatch;
  final GetBatchRawMaterials _getRawMaterials;
  final GetBatchAlerts _getAlerts;
  final GetBatchComplianceEvents _getEvents;
  final GetBatchAuditLogs _getAuditLogs;
  final ReleaseExistingBatch _release;
  final RejectExistingBatch _reject;

  Future<void> _onRequested(BatchDetailRequested event, Emitter<BatchDetailState> emit) async {
    final current = state.detail;
    emit(state.copyWith(
      detail: event.refresh && current.hasData ? current.refreshingState() : current.loading(),
    ));
    try {
      final batch = await _getBatch(batchId);
      final sections = await Future.wait<Object>([
        Section.load(() => _getRawMaterials(batchId)),
        Section.load(() => _getAlerts(batchId)),
        Section.load(() => _getEvents(batchId)),
        Section.load(() => _getAuditLogs(batchId)),
      ]);
      emit(state.copyWith(
        detail: state.detail.success(BatchDetail(
          batch: batch,
          rawMaterials: sections[0] as Section<RawMaterialUsage>,
          alerts: sections[1] as Section<DeviationAlert>,
          events: sections[2] as Section<ComplianceEvent>,
          auditLogs: sections[3] as Section<AuditLogEntry>,
        )),
      ));
    } catch (error) {
      emit(state.copyWith(detail: state.detail.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _run(
    Emitter<BatchDetailState> emit,
    BatchReviewAction action,
    Future<ProductionBatch> Function() command,
  ) async {
    final current = state.detail.data;
    if (state.submitting || current == null) return;
    emit(state.copyWith(
      actionStatus: BatchActionStatus.submitting,
      lastAction: action,
      clearActionFailure: true,
    ));
    try {
      final updated = await command();
      emit(state.copyWith(
        detail: state.detail.success(current.withBatch(updated)),
        actionStatus: BatchActionStatus.success,
      ));
      // Reload secondary sections (audit log/compliance events change).
      add(const BatchDetailRequested(refresh: true));
    } catch (error) {
      emit(state.copyWith(
        actionStatus: BatchActionStatus.failure,
        actionFailure: ApiExceptionMapper.map(error),
      ));
    }
  }
}
