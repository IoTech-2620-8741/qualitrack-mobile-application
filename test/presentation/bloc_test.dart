import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/batch/presentation/bloc/batch_detail_bloc.dart';
import 'package:qualitrack_mobile/batch/presentation/bloc/batches_bloc.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_queries.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alert_detail_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alerts_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/notifications_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/unread_notifications_controller.dart';
import 'package:qualitrack_mobile/equipment/application/equipment_queries.dart';
import 'package:qualitrack_mobile/iam/application/iam_use_cases.dart';
import 'package:qualitrack_mobile/iam/application/session_controller.dart';
import 'package:qualitrack_mobile/iam/domain/onboarding_state.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/change_password_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/sign_in_bloc.dart';
import 'package:qualitrack_mobile/laboratory/application/laboratory_queries.dart';
import 'package:qualitrack_mobile/reporting/application/reporting_queries.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';
import 'package:qualitrack_mobile/shared/presentation/view_status.dart';
import 'package:qualitrack_mobile/tracking/application/telemetry_queries.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';
import 'package:qualitrack_mobile/tracking/presentation/bloc/telemetry_dashboard_bloc.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

const lab = LaboratoryId(7);

void main() {
  setUpAll(() {
    registerFallbackValue(sessionFixture());
    registerFallbackValue(lab);
    registerFallbackValue(const TelemetryTarget(deviceId: 1, environmentId: 1, containerMonitor: false));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(batchFixture());
  });

  SessionController controllerOf(MockAuthRepository auth, MockSessionRepository sessions) => SessionController(
    restoreSession: RestoreSession(sessions),
    rememberSession: RememberSession(sessions),
    signOut: SignOut(sessions),
    checkOnboarding: CheckOnboarding(auth),
  );

  group('SessionController', () {
    late MockAuthRepository auth;
    late MockSessionRepository sessions;
    late SessionController controller;

    setUp(() {
      auth = MockAuthRepository();
      sessions = MockSessionRepository();
      when(() => sessions.clear()).thenAnswer((_) async {});
      when(() => sessions.save(any())).thenAnswer((_) async {});
      controller = controllerOf(auth, sessions);
    });

    test('no stored session → unauthenticated', () async {
      when(() => sessions.load()).thenAnswer((_) async => null);
      await controller.restore();
      expect(controller.status, SessionStatus.unauthenticated);
    });

    test('ready onboarding → authenticated', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture());
      when(() => auth.getOnboarding()).thenAnswer(
        (_) async => const OnboardingState(nextStep: OnboardingStep.ready, laboratoryId: 7),
      );
      await controller.restore();
      expect(controller.status, SessionStatus.authenticated);
      expect(controller.requireLaboratoryId(), lab);
    });

    test('temporary password → password change, then authenticated once changed', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture(passwordChangeRequired: true));
      when(() => auth.getOnboarding()).thenAnswer(
        (_) async => const OnboardingState(nextStep: OnboardingStep.passwordChange),
      );
      await controller.restore();
      expect(controller.status, SessionStatus.passwordChangeRequired);

      when(() => auth.getOnboarding()).thenAnswer((_) async => const OnboardingState(nextStep: OnboardingStep.ready));
      await controller.passwordChanged();

      expect(controller.status, SessionStatus.authenticated);
      expect(controller.session?.passwordChangeRequired, isFalse);
      verify(() => sessions.save(any())).called(1);
    });

    test('inactive subscription → setup required', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture());
      when(() => auth.getOnboarding()).thenAnswer(
        (_) async => const OnboardingState(nextStep: OnboardingStep.subscription),
      );
      await controller.restore();
      expect(controller.status, SessionStatus.setupRequired);
      expect(controller.pendingStep, OnboardingStep.subscription);
    });

    test('offline without laboratory → setup required without fallback ids', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture(laboratoryId: null));
      when(() => auth.getOnboarding()).thenThrow(const NetworkFailure());
      await controller.restore();
      expect(controller.status, SessionStatus.setupRequired);
      expect(controller.requireLaboratoryId, throwsA(isA<MissingLaboratoryFailure>()));
    });

    test('expire clears the session once and flags it', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture());
      when(() => auth.getOnboarding()).thenAnswer((_) async => const OnboardingState(nextStep: OnboardingStep.ready));
      await controller.restore();
      await controller.expire();
      await controller.expire();
      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.sessionExpired, isTrue);
      verify(() => sessions.clear()).called(1);
    });
  });

  group('SignInBloc', () {
    late MockAuthRepository auth;
    late MockSessionRepository sessions;
    late SessionController controller;

    setUp(() {
      auth = MockAuthRepository();
      sessions = MockSessionRepository();
      when(() => sessions.save(any())).thenAnswer((_) async {});
      when(() => auth.getOnboarding()).thenAnswer((_) async => const OnboardingState(nextStep: OnboardingStep.ready));
      controller = controllerOf(auth, sessions);
    });

    blocTest<SignInBloc, SignInState>(
      'emits submitting → success and authenticates the session',
      build: () {
        when(() => auth.signIn(username: 'qa@lab.test', password: 'secret')).thenAnswer((_) async => sessionFixture());
        return SignInBloc(signIn: SignIn(auth, sessions), session: controller);
      },
      act: (bloc) => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'secret')),
      expect: () => const [SignInState(status: SignInStatus.submitting), SignInState(status: SignInStatus.success)],
      verify: (_) => expect(controller.status, SessionStatus.authenticated),
    );

    blocTest<SignInBloc, SignInState>(
      'wrong credentials and deactivated accounts are shown as invalid credentials',
      build: () {
        when(() => auth.signIn(username: 'qa@lab.test', password: 'bad')).thenThrow(const ConflictFailure());
        return SignInBloc(signIn: SignIn(auth, sessions), session: controller);
      },
      act: (bloc) => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'bad')),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.failure, failure: UnauthorizedFailure(code: 'INVALID_CREDENTIALS')),
      ],
    );
  });

  group('ChangePasswordBloc', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'sends the passwords and reports success',
      build: () {
        final auth = MockAuthRepository();
        when(() => auth.changePassword(currentPassword: 'temp1234', newPassword: 'mine5678')).thenAnswer((_) async {});
        return ChangePasswordBloc(changePassword: ChangePassword(auth));
      },
      act: (bloc) => bloc.add(const PasswordChangeSubmitted(currentPassword: 'temp1234', newPassword: 'mine5678')),
      expect: () => const [
        ChangePasswordState(status: ChangePasswordStatus.submitting),
        ChangePasswordState(status: ChangePasswordStatus.success),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a wrong current password is shown as a failure',
      build: () {
        final auth = MockAuthRepository();
        when(() => auth.changePassword(currentPassword: 'wrong123', newPassword: 'mine5678'))
            .thenThrow(const BadRequestFailure(message: 'The current password is incorrect'));
        return ChangePasswordBloc(changePassword: ChangePassword(auth));
      },
      act: (bloc) => bloc.add(const PasswordChangeSubmitted(currentPassword: 'wrong123', newPassword: 'mine5678')),
      skip: 1,
      expect: () => [
        isA<ChangePasswordState>()
            .having((s) => s.status, 'status', ChangePasswordStatus.failure)
            .having((s) => s.failure?.message, 'message', 'The current password is incorrect'),
      ],
    );
  });

  group('AlertsBloc', () {
    late MockLaboratoryRepository labRepo;
    late MockEquipmentRepository equipmentRepo;
    late MockComplianceRepository complianceRepo;

    setUp(() {
      labRepo = MockLaboratoryRepository();
      equipmentRepo = MockEquipmentRepository();
      complianceRepo = MockComplianceRepository();
      when(() => labRepo.getEnvironments(lab)).thenAnswer((_) async => [storage]);
      when(() => equipmentRepo.getByLaboratory(lab)).thenAnswer((_) async => [equipmentFixture(id: 10)]);
    });

    AlertsBloc build() => AlertsBloc(
      getEnvironments: GetEnvironments(labRepo),
      getEquipments: GetEquipments(equipmentRepo),
      getAlerts: GetLaboratoryAlerts(complianceRepo),
      laboratoryId: () => lab,
    );

    blocTest<AlertsBloc, AlertsState>(
      'shows open alerts first and filters by status',
      build: () {
        when(() => complianceRepo.getEnvironmentAlerts(lab, 3)).thenAnswer(
          (_) async => [alertFixture(id: 1), alertFixture(id: 2, status: AlertStatus.resolved)],
        );
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AlertsFilterChanged(AlertFilter.resolved));
      },
      verify: (bloc) {
        expect(bloc.state.remote.data?.deviceNames[10], 'Stability Chamber');
        expect(bloc.state.remote.data?.environmentNames[3], 'Cold storage');
        expect(bloc.state.visible.map((a) => a.id), [2]);
      },
    );

    blocTest<AlertsBloc, AlertsState>(
      'errors are exposed as failures',
      build: () {
        when(() => complianceRepo.getEnvironmentAlerts(lab, 3)).thenThrow(const ServerFailure(statusCode: 500));
        return build();
      },
      act: (bloc) => bloc.add(const AlertsRequested()),
      expect: () => [
        isA<AlertsState>().having((s) => s.remote.status, 'status', ViewStatus.loading),
        isA<AlertsState>()
            .having((s) => s.remote.status, 'status', ViewStatus.failure)
            .having((s) => s.remote.failure, 'failure', isA<ServerFailure>()),
      ],
    );
  });

  group('AlertDetailBloc', () {
    late MockComplianceRepository repo;
    late MockEquipmentRepository equipmentRepo;
    late MockLaboratoryRepository labRepo;

    setUp(() {
      repo = MockComplianceRepository();
      equipmentRepo = MockEquipmentRepository();
      labRepo = MockLaboratoryRepository();
      when(() => repo.getAlert(1)).thenAnswer((_) async => alertFixture(id: 1));
      when(() => equipmentRepo.getById(lab, 10)).thenAnswer((_) async => equipmentFixture());
      when(() => labRepo.getEnvironments(lab)).thenAnswer((_) async => [storage]);
      when(() => labRepo.getStaff(lab)).thenThrow(const ForbiddenFailure());
    });

    AlertDetailBloc build() => AlertDetailBloc(
      alertId: 1,
      getAlert: GetAlertDetail(repo),
      getEquipment: GetEquipment(equipmentRepo),
      getEnvironments: GetEnvironments(labRepo),
      getUserDirectory: GetUserDirectory(labRepo),
      acknowledge: AcknowledgeAlert(repo),
      resolve: ResolveAlert(repo),
      laboratoryId: () => lab,
    );

    blocTest<AlertDetailBloc, AlertDetailState>(
      'acknowledge reloads the alert; names are optional',
      build: () {
        when(() => repo.acknowledge(1)).thenAnswer((_) async {
          when(() => repo.getAlert(1)).thenAnswer((_) async => alertFixture(id: 1, status: AlertStatus.acknowledged));
          return alertFixture(id: 1, status: AlertStatus.acknowledged);
        });
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertDetailRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AlertAcknowledgeSubmitted());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.actionStatus, ReviewActionStatus.success);
        expect(bloc.state.alert.data?.status, AlertStatus.acknowledged);
        expect(bloc.state.context.deviceName, 'Stability Chamber');
        expect(bloc.state.context.environmentName, 'Cold storage');
        expect(bloc.state.context.people, isEmpty);
      },
    );

    blocTest<AlertDetailBloc, AlertDetailState>(
      'backend rejection is shown and the alert is kept',
      build: () {
        when(() => repo.resolve(1, 'Done')).thenThrow(const ConflictFailure(message: 'Alert is already resolved'));
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertDetailRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AlertResolveSubmitted('Done'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.actionStatus, ReviewActionStatus.failure);
        expect(bloc.state.actionFailure?.message, 'Alert is already resolved');
        expect(bloc.state.alert.data?.status, AlertStatus.unresolved);
      },
    );
  });

  group('Batches', () {
    blocTest<BatchesBloc, BatchesState>(
      'filters by status and search query',
      build: () {
        final repo = MockBatchRepository();
        when(() => repo.getByLaboratory(lab)).thenAnswer(
          (_) async => [batchFixture(id: 1, batchNumber: 'LOT-A'), batchFixture(id: 2, batchNumber: 'LOT-B', status: BatchStatus.released)],
        );
        return BatchesBloc(getBatches: GetBatches(repo), laboratoryId: () => lab);
      },
      act: (bloc) async {
        bloc.add(const BatchesRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BatchesFilterChanged(BatchFilter.released));
        bloc.add(const BatchesQueryChanged('lot-b'));
      },
      verify: (bloc) {
        expect(bloc.state.summary.total, 2);
        expect(bloc.state.visible.map((b) => b.id), [2]);
      },
    );

    blocTest<BatchDetailBloc, BatchDetailState>(
      'release signs the batch and reloads its traceability',
      build: () {
        final repo = MockBatchRepository();
        final compliance = MockComplianceRepository();
        final reporting = MockReportingRepository();
        final labRepo = MockLaboratoryRepository();
        final pending = batchFixture();
        final released = batchFixture(status: BatchStatus.released);
        var current = pending;
        when(() => repo.getByLaboratory(lab)).thenAnswer((_) async => [current]);
        when(() => repo.getTraceability(lab, any())).thenAnswer((_) async => BatchTraceability(batch: current));
        when(() => repo.release(lab, pending, releaseDate: '2026-09-04', notes: 'Approved')).thenAnswer((_) async {
          current = released;
        });
        when(() => compliance.getBatchEvents(3)).thenAnswer((_) async => const []);
        when(() => reporting.getBatchAuditLogs(3)).thenAnswer((_) async => const []);
        when(() => labRepo.getStaff(lab)).thenAnswer((_) async => const []);
        return BatchDetailBloc(
          batchId: 3,
          getTraceability: GetBatchTraceability(repo),
          getEvents: GetBatchComplianceEvents(compliance),
          getAuditLogs: GetBatchAuditLogs(reporting),
          getUserDirectory: GetUserDirectory(labRepo),
          release: ReleaseBatch(repo),
          reject: RejectBatch(repo),
          laboratoryId: () => lab,
        );
      },
      act: (bloc) async {
        bloc.add(const BatchDetailRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(BatchReleaseSubmitted(date: DateTime(2026, 9, 4), notes: 'Approved'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.actionStatus, BatchActionStatus.success);
        expect(bloc.state.detail.data?.batch.status, BatchStatus.released);
      },
    );
  });

  group('TelemetryDashboardBloc', () {
    late MockEquipmentRepository equipmentRepo;
    late MockLaboratoryRepository labRepo;
    late MockTelemetryRepository telemetryRepo;

    setUp(() {
      equipmentRepo = MockEquipmentRepository();
      labRepo = MockLaboratoryRepository();
      telemetryRepo = MockTelemetryRepository();
      when(() => equipmentRepo.getByLaboratory(lab)).thenAnswer(
        (_) async => [
          equipmentFixture(id: 10),
          equipmentFixture(id: 11, name: 'Balance', deviceType: null),
          equipmentFixture(id: 12, name: 'Room sensor', deviceType: null, environmentId: 3),
        ],
      );
      when(() => labRepo.getEnvironments(lab)).thenAnswer((_) async => [storage]);
      when(() => telemetryRepo.getConnection(lab, any())).thenAnswer(
        (inv) async => DeviceConnection(
          deviceId: (inv.positionalArguments[1] as TelemetryTarget).deviceId,
          status: ConnectionStatus.connected,
        ),
      );
      when(() => telemetryRepo.getMeasurements(lab, any(), from: any(named: 'from'), to: any(named: 'to'))).thenAnswer(
        // Recent readings: live polling keeps only the last 24 hours.
        (_) async => [measurementFixture(id: 1, value: 6, measuredAt: DateTime.now().toUtc())],
      );
      when(() => telemetryRepo.getProfile(lab, any())).thenAnswer((_) async => null);
      when(() => telemetryRepo.getActuationEvents(lab, any(), from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => const []);
    });

    TelemetryDashboardBloc build() => TelemetryDashboardBloc(
      getEquipments: GetEquipments(equipmentRepo),
      getEnvironments: GetEnvironments(labRepo),
      getConnection: GetDeviceConnection(telemetryRepo),
      getMeasurements: GetMeasurements(telemetryRepo),
      getProfile: GetEnvironmentalProfile(telemetryRepo),
      getActuations: GetActuationEvents(telemetryRepo),
      laboratoryId: () => lab,
      pollInterval: const Duration(milliseconds: 20),
    );

    blocTest<TelemetryDashboardBloc, TelemetryState>(
      'offers only IoT devices, selects one and starts polling',
      build: build,
      act: (bloc) => bloc.add(const TelemetryStarted(deviceId: 10)),
      wait: const Duration(milliseconds: 250),
      verify: (bloc) {
        expect(bloc.state.catalog.data?.devices.map((d) => d.id), [10]);
        expect(bloc.state.selectedDeviceId, 10);
        expect(bloc.state.polling, isTrue);
        expect(bloc.state.snapshot.data?.readings.single.latest.value, 6);
        // Initial load + at least one poll tick.
        verify(() => telemetryRepo.getConnection(lab, any())).called(greaterThan(1));
      },
    );

    test('closing the bloc cancels the polling timer', () async {
      final bloc = build()..add(const TelemetryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await bloc.close();
      clearInteractions(telemetryRepo);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      verifyNever(() => telemetryRepo.getConnection(lab, any()));
    });

    blocTest<TelemetryDashboardBloc, TelemetryState>(
      'pausing stops polling',
      build: build,
      act: (bloc) async {
        bloc.add(const TelemetryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const TelemetryPollingPaused());
        await Future<void>.delayed(const Duration(milliseconds: 5));
        clearInteractions(telemetryRepo);
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.polling, isFalse);
        verifyNever(() => telemetryRepo.getConnection(lab, any()));
      },
    );
  });

  group('Notifications', () {
    test('opening an unread notice marks it as read and refreshes the bell', () async {
      final repo = MockNotificationRepository();
      var read = false;
      const unread = AppNotification(id: 1, type: NotificationType.alertOpened, subjectType: 'ALERT', subjectId: 9);
      final readNotice = AppNotification(
        id: 1,
        type: NotificationType.alertOpened,
        subjectType: 'ALERT',
        subjectId: 9,
        readAt: DateTime.utc(2026, 10, 5),
      );
      when(() => repo.getNotifications(limit: 50)).thenAnswer((_) async => [if (read) readNotice else unread]);
      when(() => repo.markRead(1)).thenAnswer((_) async => read = true);
      when(() => repo.getUnreadCount()).thenAnswer((_) async => read ? 0 : 1);
      final bell = UnreadNotificationsController(getUnreadCount: GetUnreadNotificationCount(repo));
      await bell.refresh();
      expect(bell.count, 1);

      final bloc = NotificationsBloc(
        getNotifications: GetNotifications(repo),
        markRead: MarkNotificationRead(repo),
        markAllRead: MarkAllNotificationsRead(repo),
        onReadChanged: bell.refresh,
      )..add(const NotificationsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state.unread, 1);

      bloc.add(const NotificationOpened(unread));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.unread, 0);
      expect(bell.count, 0);
      await bloc.close();
      bell.dispose();
    });
  });
}
