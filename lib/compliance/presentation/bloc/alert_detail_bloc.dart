import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/compliance_queries.dart';
import '../../domain/compliance.dart';

enum ReviewActionStatus { idle, submitting, success, failure }

enum AlertReviewAction { acknowledge, resolve }

sealed class AlertDetailEvent extends Equatable {
  const AlertDetailEvent();

  @override
  List<Object?> get props => [];
}

final class AlertDetailRequested extends AlertDetailEvent {
  const AlertDetailRequested();
}

final class AlertAcknowledgeSubmitted extends AlertDetailEvent {
  const AlertAcknowledgeSubmitted();
}

final class AlertResolveSubmitted extends AlertDetailEvent {
  const AlertResolveSubmitted(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

final class AlertDetailState extends Equatable {
  const AlertDetailState({
    this.alert = const RemoteState(),
    this.equipmentName,
    this.actionStatus = ReviewActionStatus.idle,
    this.lastAction,
    this.actionFailure,
  });

  final RemoteState<DeviationAlert> alert;
  final String? equipmentName;
  final ReviewActionStatus actionStatus;
  final AlertReviewAction? lastAction;
  final Failure? actionFailure;

  bool get submitting => actionStatus == ReviewActionStatus.submitting;

  AlertDetailState copyWith({
    RemoteState<DeviationAlert>? alert,
    String? equipmentName,
    ReviewActionStatus? actionStatus,
    AlertReviewAction? lastAction,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => AlertDetailState(
    alert: alert ?? this.alert,
    equipmentName: equipmentName ?? this.equipmentName,
    actionStatus: actionStatus ?? this.actionStatus,
    lastAction: lastAction ?? this.lastAction,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [alert, equipmentName, actionStatus, lastAction, actionFailure];
}

class AlertDetailBloc extends Bloc<AlertDetailEvent, AlertDetailState> {
  AlertDetailBloc({
    required this.alertId,
    required GetAlertDetail getAlert,
    required GetEquipment getEquipment,
    required AcknowledgeAlert acknowledge,
    required ResolveAlert resolve,
    required int Function() currentUserId,
  }) : _getAlert = getAlert,
       _getEquipment = getEquipment,
       _acknowledge = acknowledge,
       _resolve = resolve,
       _currentUserId = currentUserId,
       super(const AlertDetailState()) {
    on<AlertDetailRequested>(_onRequested);
    on<AlertAcknowledgeSubmitted>(_onAcknowledge);
    on<AlertResolveSubmitted>(_onResolve);
  }

  final int alertId;
  final GetAlertDetail _getAlert;
  final GetEquipment _getEquipment;
  final AcknowledgeAlert _acknowledge;
  final ResolveAlert _resolve;
  final int Function() _currentUserId;

  Future<void> _onRequested(AlertDetailRequested event, Emitter<AlertDetailState> emit) async {
    emit(state.copyWith(alert: state.alert.loading()));
    try {
      final alert = await _getAlert(alertId);
      emit(state.copyWith(alert: state.alert.success(alert)));
      await _loadEquipmentName(alert.equipmentId, emit);
    } catch (error) {
      emit(state.copyWith(alert: state.alert.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _loadEquipmentName(int equipmentId, Emitter<AlertDetailState> emit) async {
    try {
      final equipment = await _getEquipment(equipmentId);
      emit(state.copyWith(equipmentName: equipment.name));
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      // The equipment id is still displayed; the name is only a convenience.
    }
  }

  Future<void> _onAcknowledge(AlertAcknowledgeSubmitted event, Emitter<AlertDetailState> emit) =>
      _run(emit, AlertReviewAction.acknowledge, () {
        return _acknowledge(alertId: alertId, performedBy: _currentUserId());
      });

  Future<void> _onResolve(AlertResolveSubmitted event, Emitter<AlertDetailState> emit) =>
      _run(emit, AlertReviewAction.resolve, () {
        return _resolve(alertId: alertId, performedBy: _currentUserId(), resolutionNotes: event.notes);
      });

  Future<void> _run(
    Emitter<AlertDetailState> emit,
    AlertReviewAction action,
    Future<DeviationAlert> Function() command,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(
      actionStatus: ReviewActionStatus.submitting,
      lastAction: action,
      clearActionFailure: true,
    ));
    try {
      final updated = await command();
      emit(state.copyWith(
        alert: state.alert.success(updated),
        actionStatus: ReviewActionStatus.success,
      ));
    } catch (error) {
      emit(state.copyWith(
        actionStatus: ReviewActionStatus.failure,
        actionFailure: ApiExceptionMapper.map(error),
      ));
    }
  }
}
