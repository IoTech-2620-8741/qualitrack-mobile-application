import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
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

/// Names shown next to the alert; each one is optional and only a convenience.
final class AlertContext extends Equatable {
  const AlertContext({this.deviceName, this.environmentName, this.people = const {}});

  final String? deviceName;
  final String? environmentName;

  /// Full names by user account.
  final Map<int, String> people;

  @override
  List<Object?> get props => [deviceName, environmentName, people];
}

final class AlertDetailState extends Equatable {
  const AlertDetailState({
    this.alert = const RemoteState(),
    this.context = const AlertContext(),
    this.actionStatus = ReviewActionStatus.idle,
    this.lastAction,
    this.actionFailure,
  });

  final RemoteState<DeviationAlert> alert;
  final AlertContext context;
  final ReviewActionStatus actionStatus;
  final AlertReviewAction? lastAction;
  final Failure? actionFailure;

  bool get submitting => actionStatus == ReviewActionStatus.submitting;

  AlertDetailState copyWith({
    RemoteState<DeviationAlert>? alert,
    AlertContext? context,
    ReviewActionStatus? actionStatus,
    AlertReviewAction? lastAction,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => AlertDetailState(
    alert: alert ?? this.alert,
    context: context ?? this.context,
    actionStatus: actionStatus ?? this.actionStatus,
    lastAction: lastAction ?? this.lastAction,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [alert, context, actionStatus, lastAction, actionFailure];
}

class AlertDetailBloc extends Bloc<AlertDetailEvent, AlertDetailState> {
  AlertDetailBloc({
    required this.alertId,
    required GetAlertDetail getAlert,
    required GetEquipment getEquipment,
    required GetEnvironments getEnvironments,
    required GetUserDirectory getUserDirectory,
    required AcknowledgeAlert acknowledge,
    required ResolveAlert resolve,
    required LaboratoryId Function() laboratoryId,
  }) : _getAlert = getAlert,
       _getEquipment = getEquipment,
       _getEnvironments = getEnvironments,
       _getUserDirectory = getUserDirectory,
       _acknowledge = acknowledge,
       _resolve = resolve,
       _laboratoryId = laboratoryId,
       super(const AlertDetailState()) {
    on<AlertDetailRequested>(_onRequested);
    on<AlertAcknowledgeSubmitted>(_onAcknowledge);
    on<AlertResolveSubmitted>(_onResolve);
  }

  final int alertId;
  final GetAlertDetail _getAlert;
  final GetEquipment _getEquipment;
  final GetEnvironments _getEnvironments;
  final GetUserDirectory _getUserDirectory;
  final AcknowledgeAlert _acknowledge;
  final ResolveAlert _resolve;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(AlertDetailRequested event, Emitter<AlertDetailState> emit) async {
    emit(state.copyWith(alert: state.alert.loading()));
    try {
      final alert = await _getAlert(alertId);
      emit(state.copyWith(alert: state.alert.success(alert)));
      emit(state.copyWith(context: await _loadContext(alert)));
    } catch (error) {
      emit(state.copyWith(alert: state.alert.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<AlertContext> _loadContext(DeviationAlert alert) async {
    final laboratoryId = _laboratoryId();
    final device = await _optional(() async => (await _getEquipment(laboratoryId, alert.equipmentId)).name);
    final environment = await _optional(() async {
      for (final item in await _getEnvironments(laboratoryId)) {
        if (item.id == alert.environmentId) return item.name;
      }
      return null;
    });
    final people = await _optional(() => _getUserDirectory(laboratoryId));
    return AlertContext(deviceName: device, environmentName: environment, people: people ?? const {});
  }

  /// The ids are still displayed when a name cannot be read.
  Future<T?> _optional<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }

  Future<void> _onAcknowledge(AlertAcknowledgeSubmitted event, Emitter<AlertDetailState> emit) =>
      _run(emit, AlertReviewAction.acknowledge, () => _acknowledge(alertId));

  Future<void> _onResolve(AlertResolveSubmitted event, Emitter<AlertDetailState> emit) =>
      _run(emit, AlertReviewAction.resolve, () => _resolve(alertId, event.notes));

  Future<void> _run(
    Emitter<AlertDetailState> emit,
    AlertReviewAction action,
    Future<DeviationAlert> Function() command,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(actionStatus: ReviewActionStatus.submitting, lastAction: action, clearActionFailure: true));
    try {
      await command();
      // The detail includes the related automatic actions; the command result does not.
      final updated = await _getAlert(alertId);
      emit(state.copyWith(alert: state.alert.success(updated), actionStatus: ReviewActionStatus.success));
    } catch (error) {
      emit(state.copyWith(actionStatus: ReviewActionStatus.failure, actionFailure: ApiExceptionMapper.map(error)));
    }
  }
}
