import '../../../common/application/section.dart';
import '../../../common/domain/failure.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../compliance/api/index.dart';
import '../../../reporting/api/index.dart';

/// What happened to a batch, as its history shows it.
enum BatchHistoryKind {
  created,
  started,
  rawMaterialUsed,
  equipmentRegistered,
  staffRegistered,
  released,
  rejected,
  stored,
  blocked,
  compliance,
  other,
}

/// Name and values of an event that the backend records as text, in the shape
/// `BatchStoredInContainerIntegrationEvent[batchId=9, containerName=PT-01]`.
final class RecordedEvent {
  const RecordedEvent(this.name, this.values);

  final String name;

  /// Values by field; fields recorded as `null` are left out.
  final Map<String, String> values;

  static final _shape = RegExp(r'^\s*(\w+)\[(.*)\]\s*$', dotAll: true);
  static final _value = RegExp(r'(\w+)=(.*?)(?=, \w+=|$)', dotAll: true);

  /// Reads [text]; null when it does not have that shape.
  static RecordedEvent? parse(String? text) {
    final match = text == null ? null : _shape.firstMatch(text);
    if (match == null) return null;
    final values = <String, String>{};
    for (final value in _value.allMatches(match.group(2)!)) {
      final recorded = value.group(2)!.trim();
      if (recorded.isNotEmpty && recorded != 'null') values[value.group(1)!] = recorded;
    }
    return RecordedEvent(match.group(1)!, values);
  }

  /// `BatchBlockedIntegrationEvent` -> `Batch blocked`.
  String get words {
    final base = name.replaceFirst(RegExp(r'(Integration)?Event$'), '');
    final parts = base.split(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'));
    if (parts.isEmpty || parts.first.isEmpty) return name;
    return [parts.first, ...parts.skip(1).map((part) => part.toLowerCase())].join(' ');
  }
}

/// One line of the history of a batch: an audit log entry or a compliance event.
final class BatchHistoryEntry {
  const BatchHistoryEntry({
    required this.kind,
    required this.label,
    this.at,
    this.rawAt,
    this.actorUserId,
    this.values = const {},
    this.description,
    this.fromCompliance = false,
  });

  final BatchHistoryKind kind;

  /// Readable name of what happened, for kinds without a translated title.
  final String label;

  final DateTime? at;

  /// Time as the backend sent it, when it could not be read.
  final String? rawAt;

  /// User account that did it, when it was recorded.
  final int? actorUserId;

  /// Values of the recorded event, such as `containerName` or `reason`.
  final Map<String, String> values;

  /// Text to show when the values say nothing: the description of a compliance
  /// event, or the recorded text of an event that could not be read.
  final String? description;

  final bool fromCompliance;
}

/// Audit log and compliance events of a batch as a single history, newest first.
///
/// A compliance event that repeats the release or the rejection already in the
/// audit log is left out, so each decision is shown once.
final class BatchHistory {
  const BatchHistory({required this.entries, this.auditFailure, this.eventsFailure});

  factory BatchHistory.of({
    required Section<AuditLogEntry> auditLogs,
    required Section<ComplianceEvent> events,
  }) {
    final audit = auditLogs.items.map(_fromAuditLog).toList();
    final decisions = {
      for (final entry in audit)
        if (entry.kind == BatchHistoryKind.released || entry.kind == BatchHistoryKind.rejected) entry.kind,
    };
    final compliance = events.items.map(_fromComplianceEvent).where((entry) => !decisions.contains(entry.kind));
    final entries = [...audit, ...compliance].indexed.toList()
      ..sort((a, b) {
        final first = a.$2.at;
        final second = b.$2.at;
        if (first != null && second != null && first != second) return second.compareTo(first);
        if (first == null && second != null) return 1;
        if (first != null && second == null) return -1;
        return a.$1.compareTo(b.$1);
      });
    return BatchHistory(
      entries: [for (final (_, entry) in entries) entry],
      auditFailure: auditLogs.failure,
      eventsFailure: events.failure,
    );
  }

  final List<BatchHistoryEntry> entries;
  final Failure? auditFailure;
  final Failure? eventsFailure;

  static BatchHistoryEntry _fromAuditLog(AuditLogEntry log) {
    final event = RecordedEvent.parse(log.details);
    final kind = switch (event?.name) {
      'BatchCreatedIntegrationEvent' => BatchHistoryKind.created,
      'BatchStartedIntegrationEvent' => BatchHistoryKind.started,
      'RawMaterialLinkedToBatchIntegrationEvent' => BatchHistoryKind.rawMaterialUsed,
      'BatchParticipationRegisteredIntegrationEvent' => switch (event!.values['resourceType']) {
        'EQUIPMENT' => BatchHistoryKind.equipmentRegistered,
        'STAFF' => BatchHistoryKind.staffRegistered,
        _ => BatchHistoryKind.other,
      },
      'BatchReleasedIntegrationEvent' => BatchHistoryKind.released,
      'BatchRejectedIntegrationEvent' => BatchHistoryKind.rejected,
      'BatchStoredInContainerIntegrationEvent' => BatchHistoryKind.stored,
      _ => BatchHistoryKind.other,
    };
    return BatchHistoryEntry(
      kind: kind,
      label: event?.words ?? Formatters.humanize(log.action),
      at: log.timestamp,
      rawAt: log.rawTimestamp,
      actorUserId: log.performedBy,
      values: event?.values ?? const {},
      description: event == null ? log.details : null,
    );
  }

  static BatchHistoryEntry _fromComplianceEvent(ComplianceEvent event) => BatchHistoryEntry(
    kind: switch (event.eventType) {
      'BATCH_RELEASED' => BatchHistoryKind.released,
      'BATCH_REJECTED' => BatchHistoryKind.rejected,
      'BATCH_BLOCKED' => BatchHistoryKind.blocked,
      _ => BatchHistoryKind.compliance,
    },
    label: Formatters.humanize(event.eventType),
    at: event.timestamp,
    rawAt: event.rawTimestamp,
    description: event.description,
    fromCompliance: true,
  );
}
