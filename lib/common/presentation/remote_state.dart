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
  });

  final ViewStatus status;
  final T? data;
  final Failure? failure;
  final bool refreshing;

  RemoteState<T> loading() => RemoteState<T>(status: ViewStatus.loading, data: data);

  RemoteState<T> refreshingState() =>
      RemoteState<T>(status: status, data: data, failure: failure, refreshing: true);

  RemoteState<T> success(T value, {bool empty = false}) => RemoteState<T>(
    status: empty ? ViewStatus.empty : ViewStatus.success,
    data: value,
  );

  /// Keeps stale data visible when a refresh fails.
  RemoteState<T> failed(Failure error) => RemoteState<T>(
    status: data != null && status != ViewStatus.loading ? status : ViewStatus.failure,
    data: data,
    failure: error,
  );

  bool get hasData => data != null && (status == ViewStatus.success || status == ViewStatus.empty);

  @override
  List<Object?> get props => [status, data, failure, refreshing];
}
