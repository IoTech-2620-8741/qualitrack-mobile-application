import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/application/batch_use_cases.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/batch/presentation/bloc/batches_bloc.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_queries.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alert_detail_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alerts_bloc.dart';
import 'package:qualitrack_mobile/equipment/application/equipment_queries.dart';
import 'package:qualitrack_mobile/iam/application/iam_use_cases.dart';
import 'package:qualitrack_mobile/iam/application/session_controller.dart';
import 'package:qualitrack_mobile/iam/domain/onboarding_state.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/sign_in_bloc.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';
import 'package:qualitrack_mobile/shared/presentation/view_status.dart';
import 'package:qualitrack_mobile/tracking/application/telemetry_queries.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';
import 'package:qualitrack_mobile/tracking/presentation/bloc/telemetry_dashboard_bloc.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  setUpAll(() => registerFallbackValue(sessionFixture()));

  group('SessionController', () {
    late MockAuthRepository auth;
    late MockSessionRepository sessions;
    late SessionController controller;

    setUp(() {
      auth = MockAuthRepository();
      sessions = MockSessionRepository();
      when(() => sessions.clear()).thenAnswer((_) async {});
      controller = SessionController(
        restoreSession: RestoreSession(sessions),
        signOut: SignOut(sessions),
        checkOnboarding: CheckOnboarding(auth),
      );
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
      expect(controller.requireLaboratoryId(), const LaboratoryId(7));
    });

    test('missing laboratory → setup required without calling fallback ids', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture(laboratoryId: null));
      await controller.restore();
      expect(controller.status, SessionStatus.setupRequired);
      expect(controller.requireLaboratoryId, throwsA(isA<MissingLaboratoryFailure>()));
      verifyNever(() => auth.getOnboarding());
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

    test('expire clears the session once and flags it', () async {
      when(() => sessions.load()).thenAnswer((_) async => sessionFixture());
      when(() => auth.getOnboarding()).thenAnswer(
        (_) async => const OnboardingState(nextStep: OnboardingStep.ready),
      );
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
      when(() => auth.getOnboarding()).thenAnswer(
        (_) async => const OnboardingState(nextStep: OnboardingStep.ready),
      );
      controller = SessionController(
        restoreSession: RestoreSession(sessions),
        signOut: SignOut(sessions),
        checkOnboarding: CheckOnboarding(auth),
      );
    });

    blocTest<SignInBloc, SignInState>(
      'emits submitting → success and authenticates the session',
      build: () {
        when(() => auth.signIn(username: 'qa@lab.test', password: 'secret'))
            .thenAnswer((_) async => sessionFixture());
        return SignInBloc(signIn: SignIn(auth, sessions), session: controller);
      },
      act: (bloc) => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'secret')),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.success),
      ],
      verify: (_) => expect(controller.status, SessionStatus.authenticated),
    );

    blocTest<SignInBloc, SignInState>(
      'wrong credentials (400/404) are shown as invalid credentials',
      build: () {
        when(() => auth.signIn(username: 'qa@lab.test', password: 'bad'))
            .thenThrow(const BadRequestFailure(code: 'VALIDATION_ERROR'));
        return SignInBloc(signIn: SignIn(auth, sessions), session: controller);
      },
      act: (bloc) => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'bad')),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(
          status: SignInStatus.failure,
          failure: UnauthorizedFailure(code: 'INVALID_CREDENTIALS'),
        ),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'network problems keep their own failure',
      build: () {
        when(() => auth.signIn(username: 'qa@lab.test', password: 'x'))
            .thenThrow(const NetworkFailure());
        return SignInBloc(signIn: SignIn(auth, sessions), session: controller);
      },
      act: (bloc) => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'x')),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.failure, failure: NetworkFailure()),
      ],
    );
  });

  group('AlertsBloc', () {
    late MockEquipmentRepository equipmentRepo;
    late MockComplianceRepository complianceRepo;

    setUp(() {
      equipmentRepo = MockEquipmentRepository();
      complianceRepo = MockComplianceRepository();
      when(() => equipmentRepo.getByLaboratory(const LaboratoryId(7)))
          .thenAnswer((_) async => [equipmentFixture(id: 10)]);
    });

    AlertsBloc build() => AlertsBloc(
      getEquipments: GetEquipments(equipmentRepo),
      getAlerts: GetLaboratoryAlerts(complianceRepo),
      laboratoryId: () => const LaboratoryId(7),
    );

    blocTest<AlertsBloc, AlertsState>(
      'loads alerts and filters by status',
      build: () {
        when(() => complianceRepo.getEquipmentAlerts(10)).thenAnswer((_) async => [
          alertFixture(id: 1),
          alertFixture(id: 2, status: AlertStatus.resolved),
        ]);
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AlertsFilterChanged(AlertFilter.resolved));
      },
      skip: 2,
      expect: () => [
        isA<AlertsState>()
            .having((s) => s.filter, 'filter', AlertFilter.resolved)
            .having((s) => s.visible.map((a) => a.id).toList(), 'visible', [2]),
      ],
    );

    blocTest<AlertsBloc, AlertsState>(
      'no alerts → empty state',
      build: () {
        when(() => complianceRepo.getEquipmentAlerts(10)).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const AlertsRequested()),
      expect: () => [
        isA<AlertsState>().having((s) => s.remote.status, 'status', ViewStatus.loading),
        isA<AlertsState>().having((s) => s.remote.status, 'status', ViewStatus.empty),
      ],
    );

    blocTest<AlertsBloc, AlertsState>(
      'errors are exposed as failures',
      build: () {
        when(() => complianceRepo.getEquipmentAlerts(10)).thenThrow(const ServerFailure(statusCode: 500));
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

    setUp(() {
      repo = MockComplianceRepository();
      equipmentRepo = MockEquipmentRepository();
      when(() => repo.getAlert(1)).thenAnswer((_) async => alertFixture(id: 1));
      when(() => equipmentRepo.getById(10)).thenAnswer((_) async => equipmentFixture());
    });

    AlertDetailBloc build() => AlertDetailBloc(
      alertId: 1,
      getAlert: GetAlertDetail(repo),
      getEquipment: GetEquipment(equipmentRepo),
      acknowledge: AcknowledgeAlert(repo),
      resolve: ResolveAlert(repo),
      currentUserId: () => 42,
    );

    blocTest<AlertDetailBloc, AlertDetailState>(
      'acknowledge uses the signed-in user and updates the alert',
      build: () {
        when(() => repo.acknowledge(alertId: 1, performedBy: 42))
            .thenAnswer((_) async => alertFixture(id: 1, status: AlertStatus.acknowledged));
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertDetailRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AlertAcknowledgeSubmitted());
      },
      verify: (bloc) {
        expect(bloc.state.actionStatus, ReviewActionStatus.success);
        expect(bloc.state.alert.data?.status, AlertStatus.acknowledged);
        expect(bloc.state.equipmentName, 'Stability Chamber');
        verify(() => repo.acknowledge(alertId: 1, performedBy: 42)).called(1);
      },
    );

    blocTest<AlertDetailBloc, AlertDetailState>(
      'backend rejection is shown and the alert is kept',
      build: () {
        when(() => repo.resolve(alertId: 1, performedBy: 42, resolutionNotes: 'Done'))
            .thenThrow(const BadRequestFailure(message: 'Alert is already resolved'));
        return build();
      },
      act: (bloc) async {
        bloc.add(const AlertDetailRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AlertResolveSubmitted('Done'));
      },
      verify: (bloc) {
        expect(bloc.state.actionStatus, ReviewActionStatus.failure);
        expect(bloc.state.actionFailure?.message, 'Alert is already resolved');
        expect(bloc.state.alert.data?.status, AlertStatus.unresolved);
      },
    );
  });

  group('BatchesBloc', () {
    blocTest<BatchesBloc, BatchesState>(
      'filters by status and search query',
      build: () {
        final repo = MockBatchRepository();
        when(() => repo.getByLaboratory(const LaboratoryId(7))).thenAnswer((_) async => [
          batchFixture(id: 1, batchNumber: 'LOT-A'),
          batchFixture(id: 2, batchNumber: 'LOT-B', status: BatchStatus.released),
        ]);
        return BatchesBloc(getBatches: GetBatches(repo), laboratoryId: () => const LaboratoryId(7));
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
  });

  group('TelemetryDashboardBloc', () {
    late MockEquipmentRepository equipmentRepo;
    late MockTelemetryRepository telemetryRepo;

    setUp(() {
      equipmentRepo = MockEquipmentRepository();
      telemetryRepo = MockTelemetryRepository();
      when(() => equipmentRepo.getByLaboratory(const LaboratoryId(7)))
          .thenAnswer((_) async => [equipmentFixture(id: 10), equipmentFixture(id: 11, name: 'Balance')]);
      when(() => equipmentRepo.getBpmConfigs(any())).thenAnswer((_) async => const []);
      when(() => telemetryRepo.getStatus(any())).thenAnswer(
        (inv) async => EquipmentTelemetryStatus(
          equipmentId: inv.positionalArguments.first as int,
          isOnline: true,
          currentStatus: TelemetryStatus.operational,
        ),
      );
      when(() => telemetryRepo.getLatestMeasurements(any())).thenAnswer(
        (inv) async => [
          Measurement(
            id: 1,
            equipmentId: inv.positionalArguments.first as int,
            parameterName: 'Temperature',
            value: 10,
            unit: '°C',
            timestamp: DateTime.utc(2026, 6, 14),
          ),
        ],
      );
      when(
        () => telemetryRepo.getHistory(any(), from: any(named: 'from'), to: any(named: 'to')),
      ).thenAnswer((_) async => const []);
    });

    TelemetryDashboardBloc build() => TelemetryDashboardBloc(
      getEquipments: GetEquipments(equipmentRepo),
      getStatus: GetTelemetryStatus(telemetryRepo),
      getLatest: GetLatestTelemetry(telemetryRepo),
      getHistory: GetTelemetryHistory(telemetryRepo),
      getBpmConfigs: GetBpmConfigs(equipmentRepo),
      laboratoryId: () => const LaboratoryId(7),
      pollInterval: const Duration(milliseconds: 20),
    );

    blocTest<TelemetryDashboardBloc, TelemetryState>(
      'selects the requested equipment and starts polling',
      build: build,
      act: (bloc) => bloc.add(const TelemetryStarted(equipmentId: 11)),
      wait: const Duration(milliseconds: 70),
      verify: (bloc) {
        expect(bloc.state.selectedEquipmentId, 11);
        expect(bloc.state.polling, isTrue);
        expect(bloc.state.snapshot.data?.readings.single.latest.value, 10);
        // Initial load + at least one poll tick.
        verify(() => telemetryRepo.getStatus(11)).called(greaterThan(1));
      },
    );

    test('closing the bloc cancels the polling timer', () async {
      final bloc = build()..add(const TelemetryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await bloc.close();
      clearInteractions(telemetryRepo);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      verifyNever(() => telemetryRepo.getStatus(any()));
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
        verifyNever(() => telemetryRepo.getStatus(any()));
      },
    );
  });
}
