import 'package:equatable/equatable.dart';

import '../domain/failure.dart';
import 'view_status.dart';

/// Immutable state shared by read-only BLoCs:
/// Initial → Loading → Success | Empty | Failure, with an optional
/// `refreshing` flag while previously loaded data stays visible.
final class RemoteState<T> extends Equatable {
  const RemoteState({
    this.status = ViewStatus.initial,
    this.data,
    this.failure,
    this.refreshing = false,
    this.loadedAt,
  });

  final ViewStatus status;
  final T? data;
  final Failure? failure;
  final bool refreshing;

  /// When [data] was loaded, to tell how current it is ("Updated 2 min
  /// ago"). Kept while loading, refreshing or failing, since the data shown
  /// is still that one. Not part of equality: it is a note about the data.
  final DateTime? loadedAt;

  RemoteState<T> loading() => RemoteState<T>(status: ViewStatus.loading, data: data, loadedAt: loadedAt);

  RemoteState<T> refreshingState() =>
      RemoteState<T>(status: status, data: data, failure: failure, refreshing: true, loadedAt: loadedAt);

  RemoteState<T> success(T value, {bool empty = false}) => RemoteState<T>(
    status: empty ? ViewStatus.empty : ViewStatus.success,
    data: value,
    loadedAt: DateTime.now(),
  );

  /// Keeps stale data visible when a refresh fails.
  RemoteState<T> failed(Failure error) => RemoteState<T>(
    status: data != null && status != ViewStatus.loading ? status : ViewStatus.failure,
    data: data,
    failure: error,
    loadedAt: loadedAt,
  );

  bool get hasData => data != null && (status == ViewStatus.success || status == ViewStatus.empty);

  @override
  List<Object?> get props => [status, data, failure, refreshing];
}
