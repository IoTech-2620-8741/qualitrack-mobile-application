import 'package:equatable/equatable.dart';

/// Automatic action of the container related to the alert.
class RelatedActuation extends Equatable {
  const RelatedActuation({required this.id, required this.action, required this.result, this.triggerState, this.occurredAt});

  final int id;
  final String action;
  final String result;
  final String? triggerState;
  final DateTime? occurredAt;

  @override
  List<Object?> get props => [id, action, result, triggerState, occurredAt];
}
