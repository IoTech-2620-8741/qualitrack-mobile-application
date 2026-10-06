import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/compliance_queries.dart';
import '../../domain/compliance.dart';

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
    required GetNotificationPreferences getPreferences,
    required UpdateNotificationPreferences updatePreferences,
  }) : _getPreferences = getPreferences,
       _updatePreferences = updatePreferences,
       super(const NotificationPreferencesState()) {
    on<NotificationPreferencesRequested>(_onRequested);
    on<NotificationPreferencesSaved>(_onSaved);
  }

  final GetNotificationPreferences _getPreferences;
  final UpdateNotificationPreferences _updatePreferences;

  Future<void> _onRequested(NotificationPreferencesRequested event, Emitter<NotificationPreferencesState> emit) async {
    emit(state.copyWith(remote: state.remote.loading()));
    try {
      emit(state.copyWith(remote: state.remote.success(await _getPreferences())));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onSaved(NotificationPreferencesSaved event, Emitter<NotificationPreferencesState> emit) async {
    if (state.saveStatus == PreferencesSaveStatus.saving) return;
    emit(state.copyWith(saveStatus: PreferencesSaveStatus.saving));
    try {
      final saved = await _updatePreferences(event.preferences);
      emit(state.copyWith(remote: state.remote.success(saved), saveStatus: PreferencesSaveStatus.saved));
    } catch (error) {
      emit(state.copyWith(saveStatus: PreferencesSaveStatus.failure, saveFailure: ApiExceptionMapper.map(error)));
    }
  }
}
