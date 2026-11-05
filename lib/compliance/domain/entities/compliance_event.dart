import 'package:equatable/equatable.dart';

/// `ComplianceEventResource`.
class ComplianceEvent extends Equatable {
  const ComplianceEvent({
    required this.id,
    required this.eventType,
    this.relatedEntityId,
    this.description,
    this.timestamp,
    this.rawTimestamp,
    this.resolvedBy,
  });

  final int id;
  final String eventType;
  final int? relatedEntityId;
  final String? description;
  final DateTime? timestamp;
  final String? rawTimestamp;
  final int? resolvedBy;

  @override
  List<Object?> get props => [id, eventType, relatedEntityId, description, timestamp, rawTimestamp, resolvedBy];
}
