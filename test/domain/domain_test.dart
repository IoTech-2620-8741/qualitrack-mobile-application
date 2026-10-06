import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/equipment/domain/equipment.dart';
import 'package:qualitrack_mobile/iam/domain/access_token.dart';
import 'package:qualitrack_mobile/iam/domain/onboarding_state.dart';
import 'package:qualitrack_mobile/iam/domain/password_policy.dart';
import 'package:qualitrack_mobile/iam/domain/user_role.dart';
import 'package:qualitrack_mobile/laboratory/domain/laboratory.dart';
import 'package:qualitrack_mobile/profile/domain/profile.dart';
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
    test('parses every backend role, including the auditor', () {
      expect(
        UserRole.parseAll(['ROLE_ADMIN', 'ROLE_AUDITOR', 'ROLE_LAB_OPERATOR', 'ROLE_OTHER']),
        [UserRole.admin, UserRole.auditor, UserRole.labOperator],
      );
    });

    test('quality decisions belong to quality managers and admins', () {
      expect(sessionFixture(roles: [UserRole.qaManager]).canManageQuality, isTrue);
      expect(sessionFixture(roles: [UserRole.admin]).canManageQuality, isTrue);
      expect(sessionFixture(roles: [UserRole.labOperator]).canManageQuality, isFalse);
      expect(sessionFixture(roles: [UserRole.auditor]).canManageQuality, isFalse);
    });

    test('operators and quality managers attend alerts, auditors only read', () {
      expect(sessionFixture(roles: [UserRole.labOperator]).canAttendAlerts, isTrue);
      expect(sessionFixture(roles: [UserRole.qaManager]).canAttendAlerts, isTrue);
      expect(sessionFixture(roles: [UserRole.auditor]).canAttendAlerts, isFalse);
      expect(sessionFixture(roles: [UserRole.auditor]).isAuditor, isTrue);
    });

    test('laboratory id has no default value', () {
      expect(LaboratoryId.tryCreate(null), isNull);
      expect(LaboratoryId.tryCreate(0), isNull);
      expect(sessionFixture(laboratoryId: null).hasLaboratory, isFalse);
    });

    test('onboarding steps map backend codes, including the password change', () {
      expect(OnboardingStep.fromCode('READY'), OnboardingStep.ready);
      expect(OnboardingStep.fromCode('PASSWORD_CHANGE'), OnboardingStep.passwordChange);
      expect(OnboardingStep.fromCode('SUBSCRIPTION'), OnboardingStep.subscription);
      expect(OnboardingStep.fromCode('LABORATORY'), OnboardingStep.laboratory);
      expect(OnboardingStep.fromCode('OTHER'), OnboardingStep.unknown);
      expect(const OnboardingState(nextStep: OnboardingStep.passwordChange).requiresPasswordChange, isTrue);
    });

    test('a changed password clears the temporary password flag', () {
      final session = sessionFixture(passwordChangeRequired: true);
      expect(session.withPasswordChanged().passwordChangeRequired, isFalse);
      expect(session.withPasswordChanged().userId, session.userId);
    });

    test('password policy of the platform', () {
      expect(PasswordPolicy.isSatisfiedBy('abcd1234'), isTrue);
      expect(PasswordPolicy.isSatisfiedBy('añoÑ2026'), isTrue);
      expect(PasswordPolicy.isSatisfiedBy('abc123'), isFalse);
      expect(PasswordPolicy.isSatisfiedBy('abcdefgh'), isFalse);
      expect(PasswordPolicy.isSatisfiedBy('12345678'), isFalse);
      expect(PasswordPolicy.isSatisfiedBy('a1' * 37), isFalse);
    });
  });

  group('Laboratory', () {
    test('environment usages map backend codes', () {
      expect(EnvironmentUsage.fromCode('RAW_MATERIAL_STORAGE'), EnvironmentUsage.rawMaterialStorage);
      expect(EnvironmentUsage.fromCode(null), EnvironmentUsage.unassigned);
      expect(EnvironmentUsage.fromCode(''), EnvironmentUsage.unassigned);
      expect(storage.displayName, 'ALM-01 · Cold storage');
    });

    test('catalog finds the environment of a product', () {
      const catalog = ProductCatalog(environments: [storage, production], products: []);
      expect(catalog.environment(4), production);
      expect(catalog.environment(99), isNull);
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
      expect([summary.total, summary.unresolved, summary.acknowledged, summary.resolved], [3, 1, 1, 1]);
      expect(summary.critical, 1);
      expect(summary.open, 2);
    });

    test('unknown enum values are preserved as unknown', () {
      expect(AlertStatus.fromCode('X'), AlertStatus.unknown);
      expect(AlertSeverity.fromCode(null), AlertSeverity.unknown);
      expect(AlertOrigin.fromCode('ENVIRONMENT'), AlertOrigin.environment);
      expect(NotificationType.fromCode('BATCH_RELEASED'), NotificationType.batchReleased);
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
        batchFixture(id: 4, status: BatchStatus.inProgress),
      ]);
      expect([summary.total, summary.pending, summary.inProgress, summary.released, summary.rejected], [4, 1, 1, 1, 1]);
      expect(isoDate(DateTime(2026, 9, 4)), '2026-09-04');
    });
  });

  group('Inventory & Equipment', () {
    test('low stock follows the classification of the backend', () {
      expect(materialFixture(stockStatus: 'LOW', usable: 50).isBelowMinimum, isTrue);
      expect(materialFixture(stockStatus: 'SUFFICIENT', usable: 1).isBelowMinimum, isFalse);
      expect(materialFixture(stockStatus: null, usable: 3).isBelowMinimum, isTrue);
      expect(materialFixture().hasBlockedStock, isTrue);
      expect(materialFixture().matches('fe-'), isTrue);
    });

    test('only located IoT devices report telemetry', () {
      expect(equipmentFixture().isIotDevice, isTrue);
      expect(equipmentFixture().isContainerMonitor, isTrue);
      expect(equipmentFixture(deviceType: null).isIotDevice, isFalse);
      expect(IotDeviceType.fromCode('ENVIRONMENTAL_DEVICE'), IotDeviceType.environmentalDevice);
      expect(IotDeviceType.fromCode(null), isNull);
      expect(EquipmentStatus.fromCode('OUT_OF_SERVICE'), EquipmentStatus.outOfService);
    });
  });

  group('TelemetryAnalysis', () {
    final base = DateTime.utc(2026, 6, 14, 12);

    test('keeps the latest reading of each metric in metric order', () {
      final readings = TelemetryAnalysis.latestByMetric([
        measurementFixture(id: 1, value: 10, measuredAt: base),
        measurementFixture(id: 2, value: 12, measuredAt: base.add(const Duration(minutes: 1))),
        measurementFixture(id: 3, metric: MonitoredMetric.airQuality, value: 400, measuredAt: base),
      ]);
      expect(readings.map((r) => r.latest.metric), [MonitoredMetric.airQuality, MonitoredMetric.temperature]);
      expect(readings.last.latest.value, 12);
      expect(readings.last.samples, 2);
    });

    test('motion and RFID are not charted', () {
      final metrics = TelemetryAnalysis.chartMetrics([
        measurementFixture(id: 1, metric: MonitoredMetric.motion, value: 1),
        measurementFixture(id: 2, metric: MonitoredMetric.humidity, value: 50),
        measurementFixture(id: 3, metric: MonitoredMetric.rfidTag, value: null),
      ]);
      expect(metrics, [MonitoredMetric.humidity]);
    });

    test('windows are offered only when real timestamps span them', () {
      final points = [
        measurementFixture(id: 1, measuredAt: base),
        measurementFixture(id: 2, measuredAt: base.add(const Duration(minutes: 30))),
      ];
      expect(
        TelemetryAnalysis.availableWindows(points, MonitoredMetric.temperature),
        [TelemetryWindow.fifteenMinutes, TelemetryWindow.oneHour],
      );
      expect(TelemetryAnalysis.availableWindows(const [], MonitoredMetric.temperature), isEmpty);
    });

    test('series is anchored to the latest real timestamp', () {
      final points = [
        measurementFixture(id: 1, measuredAt: base),
        measurementFixture(id: 2, measuredAt: base.add(const Duration(minutes: 50))),
        measurementFixture(id: 3, measuredAt: base.add(const Duration(minutes: 60))),
        measurementFixture(id: 4, metric: MonitoredMetric.humidity, measuredAt: base.add(const Duration(minutes: 60))),
      ];
      final series = TelemetryAnalysis.series(points, MonitoredMetric.temperature, TelemetryWindow.fifteenMinutes);
      expect(series.map((p) => p.id), [2, 3]);
    });

    test('deviations are the warning and critical readings, newest first', () {
      final deviations = TelemetryAnalysis.deviations([
        measurementFixture(id: 1, state: EnvironmentalState.critical, measuredAt: base),
        measurementFixture(id: 2, measuredAt: base.add(const Duration(minutes: 5))),
        measurementFixture(id: 3, state: EnvironmentalState.warning, measuredAt: base.add(const Duration(minutes: 9))),
      ]);
      expect(deviations.map((p) => p.id), [3, 1]);
    });

    test('merge adds new readings and drops the ones out of the period', () {
      final merged = TelemetryAnalysis.merge(
        [measurementFixture(id: 1, measuredAt: base), measurementFixture(id: 2, measuredAt: base.add(const Duration(hours: 2)))],
        [measurementFixture(id: 3, measuredAt: base.add(const Duration(hours: 3))), measurementFixture(id: 2, value: 7, measuredAt: base.add(const Duration(hours: 2)))],
        base.add(const Duration(hours: 1)),
      );
      expect(merged.map((m) => m.id), [3, 2]);
      expect(merged.last.value, 7);
    });

    test('profile finds the threshold of a metric', () {
      const profile = EnvironmentalProfile(
        version: 3,
        thresholds: [MetricThreshold(metric: MonitoredMetric.temperature, normalMin: 2, normalMax: 8)],
      );
      expect(profile.thresholdFor(MonitoredMetric.temperature)?.normalMax, 8);
      expect(profile.thresholdFor(MonitoredMetric.humidity), isNull);
    });
  });

  group('Profile', () {
    test('initials and display name', () {
      const profile = UserProfile(userId: 1, username: 'lucia@senkalab.test', fullName: 'Lucía Ramos Vega');
      expect(profile.displayName, 'Lucía Ramos Vega');
      expect(profile.initials, 'LV');
      expect(const UserProfile(userId: 1, username: 'qa').initials, 'Q');
    });

    test('personal data rules of the Profile context', () {
      expect(PersonalDataRules.isValidDni('12345678'), isTrue);
      expect(PersonalDataRules.isValidDni('1234567'), isFalse);
      expect(PersonalDataRules.isValidPhone('+51 987 654 321'), isTrue);
      expect(PersonalDataRules.isValidPhone('12345'), isFalse);
      expect(PersonalDataRules.isValidFullName('A'), isFalse);
      expect(ProfilePhoto.contentTypeOf('me.JPG'), 'image/jpeg');
      expect(ProfilePhoto.contentTypeOf('me.gif'), isNull);
    });
  });
}
