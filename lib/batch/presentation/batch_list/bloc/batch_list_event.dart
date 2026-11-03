import 'package:equatable/equatable.dart';

import 'batch_list_state.dart';

sealed class BatchListEvent extends Equatable {
  const BatchListEvent();

  @override
  List<Object?> get props => [];
}

final class BatchListRequested extends BatchListEvent {
  const BatchListRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class BatchListFilterChanged extends BatchListEvent {
  const BatchListFilterChanged(this.filter);

  final BatchFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class BatchListQueryChanged extends BatchListEvent {
  const BatchListQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
