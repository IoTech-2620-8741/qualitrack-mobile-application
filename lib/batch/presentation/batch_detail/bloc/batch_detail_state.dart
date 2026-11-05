import 'package:equatable/equatable.dart';

import '../../../../compliance/api/index.dart';
import '../../../../reporting/api/index.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/presentation/remote_state.dart';
import '../../../../shared/presentation/section.dart';
import '../../../domain/entities/batch_traceability.dart';
import '../../../domain/entities/production_batch.dart';

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
