import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/failure.dart';
import '../../../common/presentation/remote_state.dart';
import '../../application/compliance_facade_service.dart';
import '../../domain/entities/notification_preferences.dart';

sealed class NotificationPreferencesEvent extends Equatable {
  const NotificationPreferencesEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationPreferencesRequested extends NotificationPreferencesEvent {
  const NotificationPreferencesRequested();
}

final class NotificationPreferencesSaved extends NotificationPreferencesEvent {
  const NotificationPreferencesSaved(this.preferences);

  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}

enum PreferencesSaveStatus { idle, saving, saved, failure }

final class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.remote = const RemoteState(),
    this.saveStatus = PreferencesSaveStatus.idle,
    this.saveFailure,
  });

  final RemoteState<NotificationPreferences> remote;
  final PreferencesSaveStatus saveStatus;
  final Failure? saveFailure;

  NotificationPreferencesState copyWith({
    RemoteState<NotificationPreferences>? remote,
    PreferencesSaveStatus? saveStatus,
    Failure? saveFailure,
  }) => NotificationPreferencesState(
    remote: remote ?? this.remote,
    saveStatus: saveStatus ?? this.saveStatus,
    saveFailure: saveFailure,
  );

  @override
  List<Object?> get props => [remote, saveStatus, saveFailure];
}

class NotificationPreferencesBloc extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  NotificationPreferencesBloc({
    required ComplianceFacadeService complianceService,
  }) : _complianceService = complianceService,
       super(const NotificationPreferencesState()) {
    on<NotificationPreferencesRequested>(_onRequested);
    on<NotificationPreferencesSaved>(_onSaved);
  }

  final ComplianceFacadeService _complianceService;

  Future<void> _onRequested(NotificationPreferencesRequested event, Emitter<NotificationPreferencesState> emit) async {
    emit(state.copyWith(remote: state.remote.loading()));
    try {
      emit(state.copyWith(remote: state.remote.success(await _complianceService.getPreferences())));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }

  Future<void> _onSaved(NotificationPreferencesSaved event, Emitter<NotificationPreferencesState> emit) async {
    if (state.saveStatus == PreferencesSaveStatus.saving) return;
    emit(state.copyWith(saveStatus: PreferencesSaveStatus.saving));
    try {
      final saved = await _complianceService.updatePreferences(event.preferences);
      emit(state.copyWith(remote: state.remote.success(saved), saveStatus: PreferencesSaveStatus.saved));
    } catch (error) {
      emit(state.copyWith(saveStatus: PreferencesSaveStatus.failure, saveFailure: Failure.from(error)));
    }
  }
}
