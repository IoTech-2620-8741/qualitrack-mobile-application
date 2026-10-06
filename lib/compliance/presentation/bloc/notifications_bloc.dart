import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/compliance_queries.dart';
import '../../domain/compliance.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class NotificationOpened extends NotificationsEvent {
  const NotificationOpened(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

final class NotificationsAllRead extends NotificationsEvent {
  const NotificationsAllRead();
}

final class NotificationsState extends Equatable {
  const NotificationsState({this.remote = const RemoteState(), this.actionFailure});

  final RemoteState<List<AppNotification>> remote;
  final Failure? actionFailure;

  int get unread => (remote.data ?? const <AppNotification>[]).where((n) => !n.isRead).length;

  NotificationsState copyWith({
    RemoteState<List<AppNotification>>? remote,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => NotificationsState(
    remote: remote ?? this.remote,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [remote, actionFailure];
}

/// Notices of the signed-in user (alert lifecycle and batch decisions).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required GetNotifications getNotifications,
    required MarkNotificationRead markRead,
    required MarkAllNotificationsRead markAllRead,
    required Future<void> Function() onReadChanged,
  }) : _getNotifications = getNotifications,
       _markRead = markRead,
       _markAllRead = markAllRead,
       _onReadChanged = onReadChanged,
       super(const NotificationsState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationOpened>(_onOpened);
    on<NotificationsAllRead>(_onAllRead);
  }

  final GetNotifications _getNotifications;
  final MarkNotificationRead _markRead;
  final MarkAllNotificationsRead _markAllRead;
  final Future<void> Function() _onReadChanged;

  Future<void> _onRequested(NotificationsRequested event, Emitter<NotificationsState> emit) async {
    final current = state.remote;
    emit(state.copyWith(remote: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final items = await _getNotifications();
      emit(state.copyWith(remote: state.remote.success(items, empty: items.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onOpened(NotificationOpened event, Emitter<NotificationsState> emit) async {
    if (event.notification.isRead) return;
    try {
      await _markRead(event.notification.id);
      await _reload(emit);
    } catch (error) {
      emit(state.copyWith(actionFailure: ApiExceptionMapper.map(error)));
    }
  }

  Future<void> _onAllRead(NotificationsAllRead event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(clearActionFailure: true));
    try {
      await _markAllRead();
      await _reload(emit);
    } catch (error) {
      emit(state.copyWith(actionFailure: ApiExceptionMapper.map(error)));
    }
  }

  Future<void> _reload(Emitter<NotificationsState> emit) async {
    final items = await _getNotifications();
    emit(state.copyWith(remote: state.remote.success(items, empty: items.isEmpty), clearActionFailure: true));
    await _onReadChanged();
  }
}
