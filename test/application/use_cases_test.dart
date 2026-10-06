import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_queries.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/iam/application/iam_use_cases.dart';
import 'package:qualitrack_mobile/inventory/application/inventory_queries.dart';
import 'package:qualitrack_mobile/laboratory/application/laboratory_queries.dart';
import 'package:qualitrack_mobile/laboratory/domain/laboratory.dart';
import 'package:qualitrack_mobile/profile/application/profile_use_cases.dart';
import 'package:qualitrack_mobile/profile/domain/profile.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';
import 'package:qualitrack_mobile/subscription/application/billing_queries.dart';
import 'package:qualitrack_mobile/subscription/domain/subscription.dart';
import 'package:qualitrack_mobile/tracking/application/telemetry_queries.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

const lab = LaboratoryId(7);
const container = TelemetryTarget(deviceId: 10, environmentId: 3, containerMonitor: true);

void main() {
  setUpAll(() {
    registerFallbackValue(sessionFixture());
    registerFallbackValue(container);
    registerFallbackValue(lab);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(batchFixture());
    registerFallbackValue(const PersonalData(fullName: 'x'));
    registerFallbackValue(ProfilePhoto(bytes: Uint8List(1), contentType: 'image/png'));
  });

  group('IAM', () {
    late MockAuthRepository auth;
    late MockSessionRepository sessions;

    setUp(() {
      auth = MockAuthRepository();
      sessions = MockSessionRepository();
    });

    test('sign in trims the username and stores the session', () async {
      final session = sessionFixture();
      when(() => auth.signIn(username: 'qa@lab.test', password: 'secret')).thenAnswer((_) async => session);
      when(() => sessions.save(any())).thenAnswer((_) async {});

      final result = await SignIn(auth, sessions)(username: '  qa@lab.test ', password: 'secret');

      expect(result, session);
      verify(() => sessions.save(session)).called(1);
    });

    test('sign in rejects empty credentials without calling the backend', () {
      expect(() => SignIn(auth, sessions)(username: ' ', password: ''), throwsA(isA<BadRequestFailure>()));
      verifyNever(() => auth.signIn(username: any(named: 'username'), password: any(named: 'password')));
    });

    test('restore clears an expired session', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture(expiresAt: DateTime.utc(2020)));
      when(() => sessions.clear()).thenAnswer((_) async {});

      expect(await RestoreSession(sessions)(), isNull);
      verify(() => sessions.clear()).called(1);
    });

    test('change password requires both passwords', () async {
      expect(
        () => ChangePassword(auth)(currentPassword: '', newPassword: 'abcd1234'),
        throwsA(isA<BadRequestFailure>()),
      );
      when(() => auth.changePassword(currentPassword: 'old12345', newPassword: 'new12345')).thenAnswer((_) async {});
      await ChangePassword(auth)(currentPassword: 'old12345', newPassword: 'new12345');
      verify(() => auth.changePassword(currentPassword: 'old12345', newPassword: 'new12345')).called(1);
    });
  });

  group('Laboratory', () {
    test('catalog adds up the products of every environment, by name', () async {
      final repo = MockLaboratoryRepository();
      when(() => repo.getEnvironments(lab)).thenAnswer((_) async => [production, storage]);
      when(() => repo.getProducts(lab, 3)).thenAnswer(
        (_) async => [const PharmaceuticalProduct(id: 1, environmentId: 3, code: 'P1', name: 'Zinc', active: true)],
      );
      when(() => repo.getProducts(lab, 4)).thenAnswer(
        (_) async => [const PharmaceuticalProduct(id: 2, environmentId: 4, code: 'P2', name: 'Amoxicillin', active: true)],
      );

      final catalog = await GetProductCatalog(repo)(lab);

      expect(catalog.environments.map((e) => e.code), ['ALM-01', 'PRD-01']);
      expect(catalog.products.map((p) => p.name), ['Amoxicillin', 'Zinc']);
    });

    test('user directory maps accounts to names', () async {
      final repo = MockLaboratoryRepository();
      when(() => repo.getStaff(lab)).thenAnswer(
        (_) async => const [
          StaffMember(id: 1, fullName: 'Lucía Ramos', active: true, userId: 5),
          StaffMember(id: 2, fullName: 'No account', active: true),
        ],
      );
      expect(await GetUserDirectory(repo)(lab), {5: 'Lucía Ramos'});
    });
  });

  group('Compliance', () {
    test('alerts of every environment are deduplicated and sorted', () async {
      final repo = MockComplianceRepository();
      when(() => repo.getEnvironmentAlerts(lab, 3)).thenAnswer(
        (_) async => [alertFixture(id: 1, timestamp: DateTime.utc(2026, 1, 1))],
      );
      when(() => repo.getEnvironmentAlerts(lab, 4)).thenAnswer(
        (_) async => [
          alertFixture(id: 2, environmentId: 4, timestamp: DateTime.utc(2026, 2, 1)),
          alertFixture(id: 1, timestamp: DateTime.utc(2026, 1, 1)),
        ],
      );

      final alerts = await GetLaboratoryAlerts(repo)(lab, [3, 4]);

      expect(alerts.map((a) => a.id), [2, 1]);
    });

    test('resolve requires notes before calling the backend', () {
      final repo = MockComplianceRepository();
      expect(() => ResolveAlert(repo)(1, '  '), throwsA(isA<BadRequestFailure>()));
      verifyNoMoreInteractions(repo);
    });

    test('preferences only accept warning or critical as minimum severity', () {
      final repo = MockNotificationRepository();
      expect(
        () => UpdateNotificationPreferences(repo)(
          const NotificationPreferences(inAppEnabled: true, emailEnabled: false, minimumSeverity: AlertSeverity.low),
        ),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNoMoreInteractions(repo);
    });
  });

  group('Batch', () {
    test('traceability looks the batch up in the laboratory first', () async {
      final repo = MockBatchRepository();
      final batch = batchFixture(id: 3);
      when(() => repo.getByLaboratory(lab)).thenAnswer((_) async => [batchFixture(id: 1), batch]);
      when(() => repo.getTraceability(lab, batch)).thenAnswer((_) async => BatchTraceability(batch: batch));

      final traceability = await GetBatchTraceability(repo)(lab, 3);

      expect(traceability.batch, batch);
    });

    test('an unknown batch is not found', () {
      final repo = MockBatchRepository();
      when(() => repo.getByLaboratory(lab)).thenAnswer((_) async => [batchFixture(id: 1)]);
      expect(() => GetBatchTraceability(repo)(lab, 99), throwsA(isA<NotFoundFailure>()));
    });

    test('release sends ISO date and trimmed notes', () async {
      final repo = MockBatchRepository();
      final batch = batchFixture();
      when(() => repo.release(lab, batch, releaseDate: '2026-09-04', notes: 'Approved')).thenAnswer((_) async {});

      await ReleaseBatch(repo)(lab, batch, releaseDate: DateTime(2026, 9, 4, 18, 30), notes: ' Approved ');

      verify(() => repo.release(lab, batch, releaseDate: '2026-09-04', notes: 'Approved')).called(1);
    });

    test('reject requires a reason', () {
      final repo = MockBatchRepository();
      expect(
        () => RejectBatch(repo)(lab, batchFixture(), rejectionDate: DateTime(2026), reason: ''),
        throwsA(isA<BadRequestFailure>()),
      );
    });
  });

  group('Telemetry', () {
    test('periods longer than 31 days are rejected before calling the backend', () {
      final repo = MockTelemetryRepository();
      final to = DateTime.utc(2026, 6, 30);
      expect(
        () => GetMeasurements(repo)(lab, container, from: to.subtract(const Duration(days: 40)), to: to),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNoMoreInteractions(repo);
    });

    test('readings of other devices of the environment are ignored', () async {
      final repo = MockTelemetryRepository();
      when(() => repo.getMeasurements(lab, container, from: any(named: 'from'), to: any(named: 'to'))).thenAnswer(
        (_) async => [measurementFixture(id: 1), measurementFixture(id: 2, deviceId: 11)],
      );
      final to = DateTime.utc(2026, 6, 30);
      final points = await GetMeasurements(repo)(lab, container, from: to.subtract(const Duration(hours: 24)), to: to);
      expect(points.map((p) => p.id), [1]);
    });

    test('connections tolerate a failing device and rethrow authentication problems', () async {
      final repo = MockTelemetryRepository();
      const other = TelemetryTarget(deviceId: 11, environmentId: 3, containerMonitor: false);
      when(() => repo.getConnection(lab, container)).thenAnswer(
        (_) async => const DeviceConnection(deviceId: 10, status: ConnectionStatus.connected),
      );
      when(() => repo.getConnection(lab, other)).thenThrow(const ServerFailure(statusCode: 500));

      expect((await GetDeviceConnections(repo)(lab, [container, other])).keys, [10]);

      when(() => repo.getConnection(lab, other)).thenThrow(const UnauthorizedFailure());
      expect(() => GetDeviceConnections(repo)(lab, [other]), throwsA(isA<UnauthorizedFailure>()));
    });

    test('environmental devices have no automatic actions', () async {
      final repo = MockTelemetryRepository();
      const environmental = TelemetryTarget(deviceId: 1, environmentId: 3, containerMonitor: false);
      expect(await GetActuationEvents(repo)(lab, environmental, from: DateTime(2026), to: DateTime(2026, 2)), isEmpty);
      verifyNoMoreInteractions(repo);
    });

    test('only located IoT devices are telemetry targets', () {
      expect(targetOf(equipmentFixture()), container);
      expect(targetOf(equipmentFixture(environmentId: null)), isNull);
      expect(targetOf(equipmentFixture(deviceType: null)), isNull);
      expect(telemetryDevices([equipmentFixture(), equipmentFixture(id: 2, deviceType: null)]).map((e) => e.id), [10]);
    });
  });

  group('Inventory', () {
    test('materials of every environment, low stock first', () async {
      final repo = MockInventoryRepository();
      when(() => repo.getMaterials(lab, 3)).thenAnswer(
        (_) async => [materialFixture(id: 1, name: 'Almidón', stockStatus: 'SUFFICIENT')],
      );
      when(() => repo.getMaterials(lab, 4)).thenAnswer(
        (_) async => [materialFixture(id: 2, environmentId: 4, name: 'Zinc', stockStatus: 'LOW')],
      );
      final materials = await GetInventoryMaterials(repo)(lab, [3, 4]);
      expect(materials.map((m) => m.id), [2, 1]);
    });
  });

  group('Profile', () {
    test('invalid personal data is not sent', () {
      final repo = MockProfileRepository();
      expect(
        () => UpdateMyProfile(repo)(const PersonalData(fullName: 'Lucía', dni: '123')),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNoMoreInteractions(repo);
    });

    test('empty optional fields are sent as null', () async {
      final repo = MockProfileRepository();
      when(() => repo.updateMine(any())).thenAnswer((_) async => const UserProfile(userId: 1, username: 'u'));
      await UpdateMyProfile(repo)(const PersonalData(fullName: ' Lucía Ramos ', dni: ' ', phoneNumber: '987654321'));
      verify(() => repo.updateMine(const PersonalData(fullName: 'Lucía Ramos', phoneNumber: '987654321'))).called(1);
    });

    test('photos over 2 MB or of other types are rejected', () {
      final repo = MockProfileRepository();
      expect(
        () => UploadMyPhoto(repo)(ProfilePhoto(bytes: Uint8List(ProfilePhoto.maxBytes + 1), contentType: 'image/png')),
        throwsA(isA<BadRequestFailure>()),
      );
      expect(
        () => UploadMyPhoto(repo)(ProfilePhoto(bytes: Uint8List(10), contentType: 'image/gif')),
        throwsA(isA<BadRequestFailure>()),
      );
      verifyNoMoreInteractions(repo);
    });
  });

  group('Subscription', () {
    test('billing summary uses the active subscription and its plan', () async {
      final repo = MockSubscriptionRepository();
      const old = Subscription(id: 1, laboratoryId: 7, planCode: 'BASIC', billingCycle: 'MONTHLY', status: 'CANCELLED');
      final active = Subscription(
        id: 2,
        laboratoryId: 7,
        planCode: 'BASIC',
        billingCycle: 'MONTHLY',
        status: 'ACTIVE',
        currentPeriodStart: DateTime.utc(2026, 10),
      );
      when(() => repo.getSubscriptions(lab)).thenAnswer((_) async => [old, active]);
      when(() => repo.getPlans()).thenAnswer(
        (_) async => const [SubscriptionPlan(code: 'BASIC', name: 'Standard Lab', billingCycle: 'MONTHLY')],
      );
      when(() => repo.getPayments(2)).thenAnswer((_) async => const []);

      final summary = await GetBillingSummary(repo)(lab);

      expect(summary.active, active);
      expect(summary.plan?.name, 'Standard Lab');
      expect(summary.subscriptions.first, active);
      expect(summary.planNameOf(old), 'Standard Lab');
      expect(
        summary.planNameOf(
          const Subscription(id: 3, laboratoryId: 7, planCode: 'PRO', billingCycle: 'YEARLY', status: 'CANCELLED'),
        ),
        'PRO',
      );
    });
  });
}
