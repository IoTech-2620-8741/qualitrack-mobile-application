import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/failure.dart';
import '../../../common/presentation/remote_state.dart';
import '../../application/compliance_facade_service.dart';
import '../../domain/entities/app_notification.dart';

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

/// Marks every notice as read on screen only; the server is told when the
/// undo window ends ([NotificationsAllReadConfirmed]) unless it is undone.
final class NotificationsAllRead extends NotificationsEvent {
  const NotificationsAllRead();
}

/// The undo window ended without undo: mark them all read on the server.
final class NotificationsAllReadConfirmed extends NotificationsEvent {
  const NotificationsAllReadConfirmed();
}

/// Undo: the notices go back to how they were; nothing reached the server.
final class NotificationsAllReadUndone extends NotificationsEvent {
  const NotificationsAllReadUndone();
}

final class NotificationsState extends Equatable {
  const NotificationsState({this.remote = const RemoteState(), this.actionFailure, this.pendingAllRead = false});

  final RemoteState<List<AppNotification>> remote;
  final Failure? actionFailure;

  /// All shown as read and waiting for the undo window to end.
  final bool pendingAllRead;

  int get unread => (remote.data ?? const <AppNotification>[]).where((n) => !n.isRead).length;

  NotificationsState copyWith({
    RemoteState<List<AppNotification>>? remote,
    Failure? actionFailure,
    bool clearActionFailure = false,
    bool? pendingAllRead,
  }) => NotificationsState(
    remote: remote ?? this.remote,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
    pendingAllRead: pendingAllRead ?? this.pendingAllRead,
  );

  @override
  List<Object?> get props => [remote, actionFailure, pendingAllRead];
}

/// Notices of the signed-in user (alert lifecycle and batch decisions).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required ComplianceFacadeService complianceService,
    required Future<void> Function() onReadChanged,
  }) : _complianceService = complianceService,
       _onReadChanged = onReadChanged,
       super(const NotificationsState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationOpened>(_onOpened);
    on<NotificationsAllRead>(_onAllRead);
    on<NotificationsAllReadConfirmed>(_onAllReadConfirmed);
    on<NotificationsAllReadUndone>(_onAllReadUndone);
  }

  final ComplianceFacadeService _complianceService;
  final Future<void> Function() _onReadChanged;

  Future<void> _onRequested(NotificationsRequested event, Emitter<NotificationsState> emit) async {
    final current = state.remote;
    emit(state.copyWith(remote: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final items = await _complianceService.getNotifications();
      emit(state.copyWith(remote: state.remote.success(items, empty: items.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }

  Future<void> _onOpened(NotificationOpened event, Emitter<NotificationsState> emit) async {
    if (event.notification.isRead) return;
    try {
      await _complianceService.markNotificationRead(event.notification.id);
      await _reload(emit);
    } catch (error) {
      emit(state.copyWith(actionFailure: Failure.from(error)));
    }
  }

  /// The notices as they were before "mark all as read", to undo it.
  List<AppNotification>? _beforeAllRead;

  void _onAllRead(NotificationsAllRead event, Emitter<NotificationsState> emit) {
    final items = state.remote.data;
    if (items == null || state.unread == 0 || state.pendingAllRead) return;
    _beforeAllRead = items;
    final now = DateTime.now();
    emit(state.copyWith(
      remote: state.remote.success([for (final n in items) n.readNow(now)]),
      pendingAllRead: true,
      clearActionFailure: true,
    ));
  }

  void _onAllReadUndone(NotificationsAllReadUndone event, Emitter<NotificationsState> emit) {
    final before = _beforeAllRead;
    if (!state.pendingAllRead || before == null) return;
    _beforeAllRead = null;
    emit(state.copyWith(remote: state.remote.success(before), pendingAllRead: false));
  }

  Future<void> _onAllReadConfirmed(NotificationsAllReadConfirmed event, Emitter<NotificationsState> emit) async {
    if (!state.pendingAllRead) return;
    final before = _beforeAllRead;
    _beforeAllRead = null;
    emit(state.copyWith(pendingAllRead: false));
    try {
      await _complianceService.markAllNotificationsRead();
      await _reload(emit);
    } catch (error) {
      // Not saved: the notices go back to unread and the failure is shown.
      emit(state.copyWith(
        remote: before == null ? null : state.remote.success(before),
        actionFailure: Failure.from(error),
      ));
    }
  }

  /// Leaving the screen inside the undo window still saves the change.
  @override
  Future<void> close() async {
    if (state.pendingAllRead) {
      _beforeAllRead = null;
      try {
        await _complianceService.markAllNotificationsRead();
        await _onReadChanged();
      } catch (_) {
        // The screen is gone; the notices stay unread and show again next time.
      }
    }
    return super.close();
  }

  Future<void> _reload(Emitter<NotificationsState> emit) async {
    final items = await _complianceService.getNotifications();
    emit(state.copyWith(remote: state.remote.success(items, empty: items.isEmpty), clearActionFailure: true));
    await _onReadChanged();
  }
}
