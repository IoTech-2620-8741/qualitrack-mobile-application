import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../compliance/application/compliance_queries.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../reporting/application/reporting_queries.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../application/batch_use_cases.dart';
import '../../domain/batch.dart';

final class BatchDetail extends Equatable {
  const BatchDetail({
    required this.traceability,
    this.events = const Section.empty(),
    this.auditLogs = const Section.empty(),
    this.people = const {},
  });

  final BatchTraceability traceability;
  final Section<ComplianceEvent> events;
  final Section<AuditLogEntry> auditLogs;

  /// Full names by user account (who signed or registered something).
  final Map<int, String> people;

  ProductionBatch get batch => traceability.batch;

  @override
  List<Object?> get props => [traceability, events, auditLogs, people];
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
    required GetBatchTraceability getTraceability,
    required GetBatchComplianceEvents getEvents,
    required GetBatchAuditLogs getAuditLogs,
    required GetUserDirectory getUserDirectory,
    required ReleaseBatch release,
    required RejectBatch reject,
    required LaboratoryId Function() laboratoryId,
  }) : _getTraceability = getTraceability,
       _getEvents = getEvents,
       _getAuditLogs = getAuditLogs,
       _getUserDirectory = getUserDirectory,
       _release = release,
       _reject = reject,
       _laboratoryId = laboratoryId,
       super(const BatchDetailState()) {
    on<BatchDetailRequested>(_onRequested);
    on<BatchReleaseSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.release,
        (batch) => _release(_laboratoryId(), batch, releaseDate: e.date, notes: e.notes),
      ),
    );
    on<BatchRejectSubmitted>(
      (e, emit) => _run(
        emit,
        BatchReviewAction.reject,
        (batch) => _reject(_laboratoryId(), batch, rejectionDate: e.date, reason: e.reason),
      ),
    );
  }

  final int batchId;
  final GetBatchTraceability _getTraceability;
  final GetBatchComplianceEvents _getEvents;
  final GetBatchAuditLogs _getAuditLogs;
  final GetUserDirectory _getUserDirectory;
  final ReleaseBatch _release;
  final RejectBatch _reject;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BatchDetailRequested event, Emitter<BatchDetailState> emit) async {
    final current = state.detail;
    emit(state.copyWith(detail: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      emit(state.copyWith(detail: state.detail.success(await _load())));
    } catch (error) {
      emit(state.copyWith(detail: state.detail.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<BatchDetail> _load() async {
    final laboratoryId = _laboratoryId();
    final traceability = await _getTraceability(laboratoryId, batchId);
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
      emit(state.copyWith(actionStatus: BatchActionStatus.failure, actionFailure: ApiExceptionMapper.map(error)));
    }
  }
}
