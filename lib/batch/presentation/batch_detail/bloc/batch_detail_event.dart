import 'package:equatable/equatable.dart';

sealed class BatchDetailEvent extends Equatable {
  const BatchDetailEvent();

  @override
  List<Object?> get props => [];
}

final class BatchDetailRequested extends BatchDetailEvent {
  const BatchDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class BatchReleaseSubmitted extends BatchDetailEvent {
  const BatchReleaseSubmitted({required this.date, required this.notes});

  final DateTime date;
  final String notes;

  @override
  List<Object?> get props => [date, notes];
}

final class BatchRejectSubmitted extends BatchDetailEvent {
  const BatchRejectSubmitted({required this.date, required this.reason});

  final DateTime date;
  final String reason;

  @override
  List<Object?> get props => [date, reason];
}
