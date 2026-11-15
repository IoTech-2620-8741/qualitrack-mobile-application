import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/batch/presentation/batch_detail/batch_history.dart';
import 'package:qualitrack_mobile/batch/presentation/widgets/batch_history_timeline.dart';
import 'package:qualitrack_mobile/common/application/section.dart';
import 'package:qualitrack_mobile/common/domain/failure.dart';
import 'package:qualitrack_mobile/compliance/api/index.dart';
import 'package:qualitrack_mobile/reporting/api/index.dart';

import '../helpers/pump_app.dart';

AuditLogEntry _log(int id, String details, {DateTime? at, int? by = 27, String action = 'UPDATE'}) =>
    AuditLogEntry(id: id, action: action, performedBy: by, timestamp: at, details: details);

ComplianceEvent _event(int id, String type, {DateTime? at, String? description}) =>
    ComplianceEvent(id: id, eventType: type, timestamp: at, description: description);

void main() {
  group('RecordedEvent', () {
    test('reads the name and values of an event recorded by the backend', () {
      final event = RecordedEvent.parse(
        'BatchRejectedIntegrationEvent[batchId=9, batchNumber=null, rejectionDate=2026-10-03, '
        'reason=Out of spec, retest pending, rejectedBy=1]',
      );

      expect(event?.name, 'BatchRejectedIntegrationEvent');
      expect(event?.values, {
        'batchId': '9',
        'rejectionDate': '2026-10-03',
        'reason': 'Out of spec, retest pending',
        'rejectedBy': '1',
      });
      expect(event?.words, 'Batch rejected');
    });

    test('ignores text with another shape', () {
      expect(RecordedEvent.parse('Batch released by QA'), isNull);
      expect(RecordedEvent.parse(null), isNull);
    });
  });

  group('BatchHistory', () {
    test('joins the audit log and the compliance events, newest first, each decision once', () {
      final history = BatchHistory.of(
        auditLogs: Section([
          _log(1, 'BatchCreatedIntegrationEvent[batchId=9, batchNumber=LOT-1]', at: DateTime.utc(2026, 9, 29, 11)),
          _log(
            2,
            'BatchParticipationRegisteredIntegrationEvent[batchId=9, resourceType=EQUIPMENT, resourceId=6, '
            'resourceName=Autoclave AV-200]',
            at: DateTime.utc(2026, 9, 29, 13),
          ),
          _log(
            3,
            'BatchReleasedIntegrationEvent[batchId=9, releaseDate=2026-10-03, releasedBy=27]',
            at: DateTime.utc(2026, 10, 3, 20),
          ),
          _log(4, 'Something without shape', action: 'UPDATE'),
        ]),
        events: Section([
          _event(5, 'BATCH_RELEASED', at: DateTime.utc(2026, 10, 3, 20, 1), description: 'Batch LOT-1 released'),
          _event(6, 'BATCH_BLOCKED', at: DateTime.utc(2026, 10, 1), description: 'Container out of range'),
        ]),
      );

      expect(history.entries.map((e) => e.kind), [
        BatchHistoryKind.released,
        BatchHistoryKind.blocked,
        BatchHistoryKind.equipmentRegistered,
        BatchHistoryKind.created,
        BatchHistoryKind.other,
      ]);
      expect(history.entries[0].fromCompliance, isFalse);
      expect(history.entries[1].fromCompliance, isTrue);
      expect(history.entries[2].values['resourceName'], 'Autoclave AV-200');
      // The raw code: the timeline names it in the language of the app.
      expect(history.entries.last.label, 'UPDATE');
      expect(history.entries.last.description, 'Something without shape');
    });

    test('keeps the compliance decision when the audit log could not be read', () {
      const failure = NetworkFailure();
      final history = BatchHistory.of(
        auditLogs: const Section.failed(failure),
        events: Section([_event(5, 'BATCH_REJECTED', description: 'Batch LOT-1 rejected')]),
      );

      expect(history.auditFailure, failure);
      expect(history.entries.single.kind, BatchHistoryKind.rejected);
      expect(history.entries.single.description, 'Batch LOT-1 rejected');
    });
  });

  group('BatchHistoryTimeline', () {
    testWidgets('shows what happened, who did it and when, without the recorded ids', (tester) async {
      final history = BatchHistory.of(
        auditLogs: Section([
          _log(
            1,
            'BatchStoredInContainerIntegrationEvent[batchId=9, laboratoryId=1, containerMonitorId=4, '
            'containerName=Container PT-01, environmentId=2]',
            at: DateTime(2026, 10, 3, 16),
          ),
          _log(
            2,
            'RawMaterialLinkedToBatchIntegrationEvent[usageId=3, batchId=9, rawMaterialName=Paracetamol USP, '
            'quantityUsed=12.5, unit=kg]',
            at: DateTime(2026, 10, 2, 9),
            by: 31,
          ),
        ]),
        events: Section([
          _event(7, 'DEVIATION_ALERT_CREATED', at: DateTime(2026, 10, 2), description: 'High temperature'),
        ]),
      );

      await tester.pumpLocalized(
        Scaffold(
          body: SingleChildScrollView(
            child: BatchHistoryTimeline(
              history: history,
              person: (userId) => userId == 27 ? 'You' : 'Andrea Salazar',
            ),
          ),
        ),
      );

      expect(find.text('Stored in a container'), findsOneWidget);
      expect(find.text('Container PT-01'), findsOneWidget);
      expect(find.textContaining('You · '), findsOneWidget);
      expect(find.text('Raw material consumed'), findsOneWidget);
      expect(find.text('Paracetamol USP · 12.5 kg'), findsOneWidget);
      expect(find.textContaining('Andrea Salazar · '), findsOneWidget);
      expect(find.text('Deviation alert created'), findsOneWidget);
      expect(find.text('Compliance'), findsOneWidget);
      expect(find.textContaining('containerMonitorId'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the newest entries and the rest on request', (tester) async {
      final history = BatchHistory.of(
        auditLogs: Section([
          for (var i = 0; i < 5; i++)
            _log(i, 'BatchCreatedIntegrationEvent[batchId=$i]', at: DateTime(2026, 10, 1 + i)),
        ]),
        events: const Section.empty(),
      );

      await tester.pumpLocalized(
        Scaffold(
          body: SingleChildScrollView(
            child: BatchHistoryTimeline(history: history, person: (_) => 'You', limit: 3),
          ),
        ),
      );

      expect(find.text('Batch registered'), findsNWidgets(3));
      expect(find.text('Showing 3 of 5'), findsOneWidget);

      await tester.tap(find.byKey(const Key('batch.history.showAll')));
      await tester.pump();

      expect(find.text('Batch registered'), findsNWidgets(5));
      expect(find.text('Showing 3 of 5'), findsNothing);
    });
  });
}
