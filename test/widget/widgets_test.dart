import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_severity.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_status.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alert_detail_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alerts_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/unread_notifications_controller.dart';
import 'package:qualitrack_mobile/compliance/presentation/screens/alert_detail_screen.dart';
import 'package:qualitrack_mobile/compliance/presentation/screens/alerts_screen.dart';
import 'package:qualitrack_mobile/equipment/presentation/widgets/equipment_labels.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/change_password_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/sign_in_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/screens/change_password_screen.dart';
import 'package:qualitrack_mobile/iam/presentation/screens/sign_in_screen.dart';
import 'package:qualitrack_mobile/common/domain/failure.dart';
import 'package:qualitrack_mobile/common/presentation/i18n/app_localizations.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/state_views.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/metric_threshold.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/monitored_metric.dart';
import 'package:qualitrack_mobile/tracking/presentation/screens/telemetry_dashboard_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

class MockSignInBloc extends MockBloc<SignInEvent, SignInState> implements SignInBloc {}

class MockChangePasswordBloc extends MockBloc<PasswordChangeSubmitted, ChangePasswordState>
    implements ChangePasswordBloc {}

class MockAlertsBloc extends MockBloc<AlertsEvent, AlertsState> implements AlertsBloc {}

class MockAlertDetailBloc extends MockBloc<AlertDetailEvent, AlertDetailState> implements AlertDetailBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SignInSubmitted(username: '', password: ''));
    registerFallbackValue(const PasswordChangeSubmitted(currentPassword: '', newPassword: ''));
    registerFallbackValue(const AlertsRequested());
    registerFallbackValue(const AlertDetailRequested());
  });

  group('Sign In', () {
    late MockSignInBloc bloc;

    setUp(() {
      bloc = MockSignInBloc();
      when(() => bloc.state).thenReturn(const SignInState());
    });

    Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) => tester.pumpLocalized(
      BlocProvider<SignInBloc>.value(value: bloc, child: const SignInScreen()),
      locale: locale,
    );

    testWidgets('validates required fields and has no sign-up entry', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('signIn.submit')));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.textContaining("Don't have an account"), findsNothing);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('submits credentials and toggles password visibility', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('signIn.username')), 'qa@lab.test');
      await tester.enterText(find.byKey(const Key('signIn.password')), 'secret');

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);

      await tester.tap(find.byKey(const Key('signIn.submit')));
      await tester.pump();
      verify(() => bloc.add(const SignInSubmitted(username: 'qa@lab.test', password: 'secret'))).called(1);
    });

    testWidgets('shows backend errors and is localized in Spanish', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable(const [
          SignInState(status: SignInStatus.submitting),
          SignInState(status: SignInStatus.failure, failure: NetworkFailure()),
        ]),
        initialState: const SignInState(),
      );
      await pump(tester, locale: const Locale('es'));
      await tester.pump();
      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Usuario'), findsOneWidget);
    });
  });

  group('Forced password change', () {
    late MockChangePasswordBloc bloc;

    setUp(() {
      bloc = MockChangePasswordBloc();
      when(() => bloc.state).thenReturn(const ChangePasswordState());
    });

    Future<void> pump(WidgetTester tester) => tester.pumpLocalized(
      BlocProvider<ChangePasswordBloc>.value(
        value: bloc,
        child: ChangePasswordScreen(forced: true, onChanged: () async {}, onSignOut: () async {}),
      ),
      size: const Size(390, 844),
    );

    testWidgets('explains the rule and checks the confirmation', (tester) async {
      await pump(tester);
      expect(find.text('Choose your password'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('changePassword.current')), 'temp1234');
      await tester.enterText(find.byKey(const Key('changePassword.new')), 'short');
      await tester.enterText(find.byKey(const Key('changePassword.confirm')), 'other');
      await tester.ensureVisible(find.byKey(const Key('changePassword.submit')));
      await tester.tap(find.byKey(const Key('changePassword.submit')));
      await tester.pump();

      expect(find.text('Between 8 and 72 characters, with letters and numbers.'), findsWidgets);
      expect(find.text('The passwords do not match.'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('submits a valid change', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('changePassword.current')), 'temp1234');
      await tester.enterText(find.byKey(const Key('changePassword.new')), 'mine5678');
      await tester.enterText(find.byKey(const Key('changePassword.confirm')), 'mine5678');
      await tester.ensureVisible(find.byKey(const Key('changePassword.submit')));
      await tester.tap(find.byKey(const Key('changePassword.submit')));
      await tester.pump();

      verify(() => bloc.add(const PasswordChangeSubmitted(currentPassword: 'temp1234', newPassword: 'mine5678'))).called(1);
    });
  });

  group('Labels', () {
    testWidgets('IoT devices are named by their role and open ranges by their bound', (tester) async {
      late BuildContext context;
      await tester.pumpLocalized(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );

      expect(equipmentFixture().typeLabel(context.i18n), 'Container monitor');
      expect(equipmentFixture(deviceType: null).typeLabel(context.i18n), 'Chamber');
      expect(
        rangeText(
          context,
          const MetricThreshold(
            metric: MonitoredMetric.luminosity,
            unit: 'lux',
            normalMax: 300,
            criticalMin: 2,
            criticalMax: 500,
          ),
        ),
        'normal ≤ 300 lux · critical 2–500 lux',
      );
      expect(
        rangeText(context, const MetricThreshold(metric: MonitoredMetric.temperature, unit: '°C', normalMin: 2)),
        'normal ≥ 2 °C',
      );
    });
  });

  group('State views', () {
    testWidgets('empty state shows the default message', (tester) async {
      await tester.pumpLocalized(const Scaffold(body: EmptyView()));
      expect(find.text('No information available'), findsOneWidget);
    });

    testWidgets('error state shows a readable message and retries', (tester) async {
      var retried = false;
      await tester.pumpLocalized(
        Scaffold(body: ErrorView(failure: const TimeoutFailure(), onRetry: () => retried = true)),
      );
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('took too long'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('Alerts', () {
    late UnreadNotificationsController bell;

    setUp(() {
      final repo = MockComplianceRepository();
      when(() => repo.getUnreadCount()).thenAnswer((_) async => 2);
      bell = UnreadNotificationsController(complianceService: complianceFacade(repo));
    });

    tearDown(() => bell.dispose());

    testWidgets('renders the summary and the names without a bell or overflow at 360x640', (tester) async {
      await bell.refresh();
      final bloc = MockAlertsBloc();
      when(() => bloc.state).thenReturn(
        AlertsState(
          filter: AlertFilter.all,
          remote: RemoteState(
            status: ViewStatus.success,
            data: AlertsData(
              alerts: [alertFixture(id: 1), alertFixture(id: 2, status: AlertStatus.resolved, severity: AlertSeverity.low)],
              deviceNames: const {10: 'Stability Chamber with a very long descriptive name'},
              environmentNames: const {3: 'Cold storage'},
            ),
          ),
        ),
      );

      await tester.pumpLocalized(BlocProvider<AlertsBloc>.value(value: bloc, child: const AlertsScreen()));

      expect(find.text('Temperature'), findsWidgets);
      expect(find.textContaining('Cold storage'), findsWidgets);
      expect(find.textContaining('38.6'), findsWidgets);
      expect(find.bySemanticsLabel('Showing: All, 2 of 2'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the FAB menu lists the filters with their counts and applies the chosen one', (tester) async {
      await bell.refresh();
      final bloc = MockAlertsBloc();
      when(() => bloc.state).thenReturn(
        AlertsState(
          filter: AlertFilter.open,
          remote: RemoteState(
            status: ViewStatus.success,
            data: AlertsData(
              alerts: [alertFixture(id: 1), alertFixture(id: 2, status: AlertStatus.resolved, severity: AlertSeverity.low)],
              deviceNames: const {},
              environmentNames: const {},
            ),
          ),
        ),
      );

      await tester.pumpLocalized(BlocProvider<AlertsBloc>.value(value: bloc, child: const AlertsScreen()));
      expect(find.text('SHOWING: OPEN'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);

      await tester.tap(find.byTooltip('Filter alerts'));
      await tester.pumpAndSettle();
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.bySemanticsLabel('Resolved, 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const AlertsFilterChanged(AlertFilter.resolved))).called(1);
      expect(find.text('Resolved'), findsNothing);
    });

    testWidgets('the search matches the variable, the device and the area', (tester) async {
      await bell.refresh();
      final bloc = MockAlertsBloc();
      AlertsState withQuery(String query) => AlertsState(
        filter: AlertFilter.all,
        query: query,
        remote: RemoteState(
          status: ViewStatus.success,
          data: AlertsData(
            alerts: [alertFixture(id: 1)],
            deviceNames: const {10: 'Stability Chamber'},
            environmentNames: const {3: 'Cold storage'},
          ),
        ),
      );

      for (final query in ['temperat', 'chamber', 'COLD']) {
        when(() => bloc.state).thenReturn(withQuery(query));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpLocalized(BlocProvider<AlertsBloc>.value(value: bloc, child: const AlertsScreen()));
        expect(find.bySemanticsLabel('Showing: All, 1 of 1'), findsOneWidget, reason: query);
      }

      when(() => bloc.state).thenReturn(withQuery('humidity'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpLocalized(BlocProvider<AlertsBloc>.value(value: bloc, child: const AlertsScreen()));
      expect(find.bySemanticsLabel('Showing: All, 0 of 1'), findsOneWidget);
      expect(find.text('No results match the current filters'), findsOneWidget);
    });
  });

  group('Alert detail', () {
    late MockAlertDetailBloc bloc;

    setUp(() {
      bloc = MockAlertDetailBloc();
      when(() => bloc.state).thenReturn(
        AlertDetailState(
          alert: RemoteState(status: ViewStatus.success, data: alertFixture(id: 1)),
          context: const AlertContext(deviceName: 'Stability Chamber', environmentName: 'Cold storage'),
        ),
      );
    });

    Future<void> pump(WidgetTester tester, {required bool canAttend}) => tester.pumpLocalized(
      BlocProvider<AlertDetailBloc>.value(value: bloc, child: AlertDetailScreen(canAttend: canAttend, currentUserId: 42)),
      size: const Size(390, 844),
    );

    testWidgets('operators and quality managers acknowledge after confirming', (tester) async {
      await pump(tester, canAttend: true);
      await tester.scrollUntilVisible(find.byKey(const Key('alert.acknowledge')), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(const Key('alert.acknowledge')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alert.acknowledge')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const AlertAcknowledgeSubmitted())).called(1);
    });

    testWidgets('resolve requires notes', (tester) async {
      await pump(tester, canAttend: true);
      await tester.scrollUntilVisible(find.byKey(const Key('alert.resolve')), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(const Key('alert.resolve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alert.resolve')));
      await tester.pump();
      expect(find.text('Resolution notes are required'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<AlertResolveSubmitted>())));
    });

    testWidgets('auditors only read', (tester) async {
      await pump(tester, canAttend: false);
      expect(find.byKey(const Key('alert.acknowledge')), findsNothing);
      expect(find.byKey(const Key('alert.resolve')), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('Auditors consult alerts'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Auditors consult alerts'), findsOneWidget);
    });
  });
}
