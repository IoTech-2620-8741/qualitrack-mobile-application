import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/equipment/domain/equipment.dart';
import 'package:qualitrack_mobile/iam/domain/access_token.dart';
import 'package:qualitrack_mobile/iam/domain/onboarding_state.dart';
import 'package:qualitrack_mobile/iam/domain/user_role.dart';
import 'package:qualitrack_mobile/inventory/domain/inventory.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';

import '../helpers/fixtures.dart';

void main() {
  group('AccessToken', () {
    test('reads exp claim and detects expiration', () {
      final expires = DateTime.utc(2030, 1, 1);
      final token = AccessToken.fromJwt(fakeJwt(expiresAt: expires));
      expect(token.expiresAt, expires);
      expect(token.isExpired(DateTime.utc(2029, 12, 31)), isFalse);
      expect(token.isExpired(DateTime.utc(2030, 1, 1)), isTrue);
    });

    test('malformed token has no expiration but empty token is expired', () {
      expect(AccessToken.fromJwt('not-a-jwt').expiresAt, isNull);
      expect(const AccessToken('').isExpired(DateTime.now()), isTrue);
    });
  });

  group('UserRole & UserSession', () {
    test('parses only backend roles', () {
      expect(
        UserRole.parseAll(['ROLE_ADMIN', 'ROLE_AUDITOR', 'ROLE_LAB_OPERATOR']),
        [UserRole.admin, UserRole.labOperator],
      );
    });

    test('review is offered only to QA managers and admins', () {
      expect(sessionFixture(roles: [UserRole.qaManager]).canReview, isTrue);
      expect(sessionFixture(roles: [UserRole.admin]).canReview, isTrue);
      expect(sessionFixture(roles: [UserRole.labOperator]).canReview, isFalse);
    });

    test('laboratory id has no default value', () {
      expect(LaboratoryId.tryCreate(null), isNull);
      expect(LaboratoryId.tryCreate(0), isNull);
      expect(sessionFixture(laboratoryId: null).hasLaboratory, isFalse);
    });

    test('onboarding steps map backend codes', () {
      expect(OnboardingStep.fromCode('READY'), OnboardingStep.ready);
      expect(OnboardingStep.fromCode('SUBSCRIPTION'), OnboardingStep.subscription);
      expect(OnboardingStep.fromCode('LABORATORY'), OnboardingStep.laboratory);
      expect(OnboardingStep.fromCode('OTHER'), OnboardingStep.unknown);
    });
  });

  group('DeviationAlert', () {
    test('lifecycle hints mirror backend rules', () {
      expect(alertFixture(status: AlertStatus.unresolved).canAcknowledge, isTrue);
      expect(alertFixture(status: AlertStatus.acknowledged).canAcknowledge, isFalse);
      expect(alertFixture(status: AlertStatus.acknowledged).canResolve, isTrue);
      expect(alertFixture(status: AlertStatus.resolved).canResolve, isFalse);
    });

    test('priority: open critical first, then newest', () {
      final alerts = [
        alertFixture(id: 1, status: AlertStatus.resolved),
        alertFixture(id: 2, severity: AlertSeverity.warning, timestamp: DateTime.utc(2026, 9, 2)),
        alertFixture(id: 3, timestamp: DateTime.utc(2026, 9, 1)),
        alertFixture(id: 4, timestamp: DateTime.utc(2026, 9, 3)),
      ]..sort(DeviationAlert.compareByPriority);
      expect(alerts.map((a) => a.id), [4, 3, 2, 1]);
    });

    test('summary counts statuses and open critical alerts', () {
      final summary = AlertSummary.of([
        alertFixture(id: 1),
        alertFixture(id: 2, status: AlertStatus.acknowledged, severity: AlertSeverity.low),
        alertFixture(id: 3, status: AlertStatus.resolved),
      ]);
      expect(summary.total, 3);
      expect(summary.unresolved, 1);
      expect(summary.acknowledged, 1);
      expect(summary.resolved, 1);
      expect(summary.critical, 1);
      expect(summary.open, 2);
    });

    test('unknown enum values are preserved as unknown', () {
      expect(AlertStatus.fromCode('X'), AlertStatus.unknown);
      expect(AlertSeverity.fromCode(null), AlertSeverity.unknown);
    });
  });

  group('Batch', () {
    test('only open batches await review', () {
      expect(batchFixture(status: BatchStatus.pending).isAwaitingReview, isTrue);
      expect(batchFixture(status: BatchStatus.inProgress).isAwaitingReview, isTrue);
      expect(batchFixture(status: BatchStatus.released).isAwaitingReview, isFalse);
      expect(batchFixture(status: BatchStatus.rejected).isAwaitingReview, isFalse);
    });

    test('summary and iso date formatting', () {
      final summary = BatchSummary.of([
        batchFixture(id: 1),
        batchFixture(id: 2, status: BatchStatus.released),
        batchFixture(id: 3, status: BatchStatus.rejected),
      ]);
      expect([summary.total, summary.pending, summary.released, summary.rejected], [3, 1, 1, 1]);
      expect(isoDate(DateTime(2026, 9, 4)), '2026-09-04');
    });
  });

  group('Inventory & Equipment', () {
    test('below minimum uses usable stock', () {
      const material = InventoryMaterial(
        id: 1,
        laboratoryId: 7,
        code: 'FE-01',
        name: 'Hierro',
        unit: 'g',
        minimumStock: 5,
        usableStock: 3,
        physicalStock: 10,
      );
      expect(material.isBelowMinimum, isTrue);
      expect(material.hasBlockedStock, isTrue);
      expect(material.matches('fe-'), isTrue);
    });

    test('BPM limits check values and parameter names', () {
      const limit = BpmParameterConfig(
        id: 1,
        equipmentId: 10,
        parameterName: 'Temperature',
        minValue: 8,
        maxValue: 15,
        unit: '°C',
      );
      expect(limit.appliesTo(' temperature '), isTrue);
      expect(limit.isWithin(10), isTrue);
      expect(limit.isWithin(16), isFalse);
    });

    test('equipment attention and search', () {
      final eq = equipmentFixture();
      expect(eq.needsAttention, isFalse);
      expect(eq.matches('esp32'), isTrue);
      expect(EquipmentStatus.fromCode('OUT_OF_SERVICE'), EquipmentStatus.outOfService);
    });
  });

  group('TelemetryAnalysis', () {
    Measurement m(int id, String p, double v, DateTime t) => Measurement(
      id: id,
      equipmentId: 10,
      parameterName: p,
      value: v,
      unit: p == 'Temperature' ? '°C' : '%',
      timestamp: t,
    );

    TelemetryHistoryPoint h(int id, String p, DateTime t, {bool anomaly = false}) =>
        TelemetryHistoryPoint(
          id: id,
          equipmentId: 10,
          parameterName: p,
          recordedValue: id.toDouble(),
          isAnomaly: anomaly,
          timestamp: t,
        );

    final base = DateTime.utc(2026, 6, 14, 12);

    test('keeps the latest reading of each parameter (no fixed sensor set)', () {
      final readings = TelemetryAnalysis.latestByParameter([
        m(1, 'Temperature', 10, base),
        m(2, 'Temperature', 12, base.add(const Duration(minutes: 1))),
        m(3, 'Humidity', 52, base),
      ]);
      expect(readings.map((r) => r.latest.parameterName), ['Humidity', 'Temperature']);
      expect(readings.last.latest.value, 12);
      expect(readings.last.samples, 2);
    });

    test('windows are offered only when real timestamps span them', () {
      final points = [
        h(1, 'Temperature', base),
        h(2, 'Temperature', base.add(const Duration(minutes: 30))),
      ];
      expect(
        TelemetryAnalysis.availableWindows(points, 'Temperature'),
        [TelemetryWindow.fifteenMinutes, TelemetryWindow.oneHour],
      );
      expect(TelemetryAnalysis.availableWindows(const [], 'Temperature'), isEmpty);
    });

    test('series is anchored to the latest real timestamp', () {
      final points = [
        h(1, 'Temperature', base),
        h(2, 'Temperature', base.add(const Duration(minutes: 50))),
        h(3, 'Temperature', base.add(const Duration(minutes: 60))),
        h(4, 'Humidity', base.add(const Duration(minutes: 60))),
      ];
      final series = TelemetryAnalysis.series(points, 'Temperature', TelemetryWindow.fifteenMinutes);
      expect(series.map((p) => p.id), [2, 3]);
    });

    test('anomalies newest first', () {
      final anomalies = TelemetryAnalysis.anomalies([
        h(1, 'Temperature', base, anomaly: true),
        h(2, 'Temperature', base.add(const Duration(minutes: 5))),
        h(3, 'Temperature', base.add(const Duration(minutes: 9)), anomaly: true),
      ]);
      expect(anomalies.map((p) => p.id), [3, 1]);
    });
  });
}
