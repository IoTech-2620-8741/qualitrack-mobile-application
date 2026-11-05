/// This file contains the entities related to Audit Reports and Logs.
///
import 'package:equatable/equatable.dart';

/// Represents an audit report (PDF or CSV) available for download.
final class AuditReport extends Equatable {
  const AuditReport({
    required this.id,
    required this.reportType,
    this.laboratoryId,
    this.batchId,
    this.equipmentId,
    this.generatedByName,
    this.dateRangeFrom,
    this.dateRangeTo,
    this.generatedAt,
    this.checksum,
  });

  final int id;
  final String reportType;
  final int? laboratoryId;
  final int? batchId;
  final int? equipmentId;
  final String? generatedByName;
  final String? dateRangeFrom;
  final String? dateRangeTo;
  final DateTime? generatedAt;
  final String? checksum;

  @override
  List<Object?> get props => [
    id, reportType, laboratoryId, batchId, equipmentId,
    generatedByName, dateRangeFrom, dateRangeTo, generatedAt, checksum,
  ];
}

/// Represents an entry in the system's audit log.
final class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.action,
    this.entityType,
    this.entityId,
    this.performedBy,
    this.timestamp,
    this.rawTimestamp,
    this.details,
  });

  final int id;
  final String action;
  final String? entityType;
  final int? entityId;
  final int? performedBy;
  final DateTime? timestamp;
  final String? rawTimestamp;
  final String? details;

  @override
  List<Object?> get props => [id, action, entityType, entityId, performedBy, timestamp, rawTimestamp, details];
}