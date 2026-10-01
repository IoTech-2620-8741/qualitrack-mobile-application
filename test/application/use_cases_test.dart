import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_queries.dart';
import 'package:qualitrack_mobile/iam/application/iam_use_cases.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/tracking/application/telemetry_queries.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  setUpAll(() => registerFallbackValue(sessionFixture()));

  group('SignIn', () {
    late MockAuthRepository auth;
    late MockSessionRepository sessions;

    setUp(() {
      auth = MockAuthRepository();
      sessions = MockSessionRepository();
    });

    test('trims username, signs in and stores the session', () async {
      final session = sessionFixture();
      when(() => auth.signIn(username: 'qa@lab.test', password: 'secret'))
          .thenAnswer((_) async => session);
      when(() => sessions.save(any())).thenAnswer((_) async {});

      final result = await SignIn(auth, sessions)(username: '  qa@lab.test ', password: 'secret');

      expect(result, session);
      verify(() => sessions.save(session)).called(1);
    });

    test('rejects empty credentials without calling the backend', () {
      expect(
        () => SignIn(auth, sessions)(username: ' ', password: ''),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNever(() => auth.signIn(username: any(named: 'username'), password: any(named: 'password')));
    });
  });

  group('RestoreSession', () {
    test('clears an expired session', () async {
      final sessions = MockSessionRepository();
      when(() => sessions.load()).thenAnswer(
        (_) async => sessionFixture(expiresAt: DateTime.utc(2020)),
      );
      when(() => sessions.clear()).thenAnswer((_) async {});

      expect(await RestoreSession(sessions)(), isNull);
      verify(() => sessions.clear()).called(1);
    });

    test('returns a valid session', () async {
      final sessions = MockSessionRepository();
      final session = sessionFixture();
      when(() => sessions.load()).thenAnswer((_) async => session);
      expect(await RestoreSession(sessions)(), session);
    });
  });

  group('Compliance', () {
    test('aggregates alerts per equipment, deduplicates and sorts', () async {
      final repo = MockComplianceRepository();
      when(() => repo.getEquipmentAlerts(1)).thenAnswer((_) async => [
        alertFixture(id: 1, equipmentId: 1, timestamp: DateTime.utc(2026, 1, 1)),
      ]);
      when(() => repo.getEquipmentAlerts(2)).thenAnswer((_) async => [
        alertFixture(id: 2, equipmentId: 2, timestamp: DateTime.utc(2026, 2, 1)),
        // An alert that does not belong to the requested equipment is ignored.
        alertFixture(id: 9, equipmentId: 1),
      ]);

      final alerts = await GetLaboratoryAlerts(repo)([1, 2]);

      expect(alerts.map((a) => a.id), [2, 1]);
    });

    test('resolve requires notes before calling the backend', () {
      final repo = MockComplianceRepository();
      expect(
        () => ResolveAlert(repo)(alertId: 1, performedBy: 42, resolutionNotes: '  '),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNoMoreInteractions(repo);
    });
  });

  group('Batch review', () {
    test('release sends ISO date and trimmed notes', () async {
      final repo = MockBatchRepository();
      when(() => repo.release(batchId: 3, releaseDate: '2026-09-04', notes: 'Approved'))
          .thenAnswer((_) async => batchFixture());

      await ReleaseExistingBatch(repo)(
        batchId: 3,
        releaseDate: DateTime(2026, 9, 4, 18, 30),
        notes: ' Approved ',
      );

      verify(() => repo.release(batchId: 3, releaseDate: '2026-09-04', notes: 'Approved')).called(1);
    });

    test('reject requires a reason', () {
      final repo = MockBatchRepository();
      expect(
        () => RejectExistingBatch(repo)(batchId: 3, rejectionDate: DateTime(2026), reason: ''),
        throwsA(isA<BadRequestFailure>()),
      );
    });
  });

  group('Telemetry', () {
    test('history range is only sent when both bounds are present', () async {
      final repo = MockTelemetryRepository();
      when(() => repo.getHistory(10, from: null, to: null)).thenAnswer((_) async => const []);
      await GetTelemetryHistory(repo)(10, from: DateTime(2026));
      verify(() => repo.getHistory(10, from: null, to: null)).called(1);
    });

    test('statuses tolerate a single failing equipment', () async {
      final repo = MockTelemetryRepository();
      when(() => repo.getStatus(1)).thenAnswer(
        (_) async => const EquipmentTelemetryStatus(
          equipmentId: 1,
          isOnline: true,
          currentStatus: TelemetryStatus.operational,
        ),
      );
      when(() => repo.getStatus(2)).thenThrow(const ServerFailure(statusCode: 500));

      final statuses = await GetTelemetryStatuses(repo)([1, 2]);

      expect(statuses.keys, [1]);
    });

    test('statuses rethrow authentication failures', () {
      final repo = MockTelemetryRepository();
      when(() => repo.getStatus(1)).thenThrow(const UnauthorizedFailure());
      expect(() => GetTelemetryStatuses(repo)([1]), throwsA(isA<UnauthorizedFailure>()));
    });
  });
}
