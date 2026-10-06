import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/compliance/application/compliance_queries.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alert_detail_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alerts_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/unread_notifications_controller.dart';
import 'package:qualitrack_mobile/compliance/presentation/pages/alert_detail_page.dart';
import 'package:qualitrack_mobile/compliance/presentation/pages/alerts_page.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/change_password_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/sign_in_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/pages/change_password_page.dart';
import 'package:qualitrack_mobile/iam/presentation/pages/sign_in_page.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/presentation/remote_state.dart';
import 'package:qualitrack_mobile/shared/presentation/view_status.dart';
import 'package:qualitrack_mobile/shared/presentation/widgets/state_views.dart';

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
      BlocProvider<SignInBloc>.value(value: bloc, child: const SignInPage()),
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
        child: ChangePasswordPage(forced: true, onChanged: () async {}, onSignOut: () async {}),
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
      final repo = MockNotificationRepository();
      when(() => repo.getUnreadCount()).thenAnswer((_) async => 2);
      bell = UnreadNotificationsController(getUnreadCount: GetUnreadNotificationCount(repo));
    });

    tearDown(() => bell.dispose());

    testWidgets('renders counters, names and the bell without overflow at 360x640', (tester) async {
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

      await tester.pumpLocalized(BlocProvider<AlertsBloc>.value(value: bloc, child: AlertsPage(notifications: bell)));

      expect(find.text('Temperature'), findsWidgets);
      expect(find.text('Cold storage'), findsWidgets);
      expect(find.textContaining('38.6'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(tester.takeException(), isNull);
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
      BlocProvider<AlertDetailBloc>.value(value: bloc, child: AlertDetailPage(canAttend: canAttend, currentUserId: 42)),
      size: const Size(390, 844),
    );

    testWidgets('operators and quality managers acknowledge after confirming', (tester) async {
      await pump(tester, canAttend: true);
      await tester.scrollUntilVisible(find.byKey(const Key('alert.acknowledge')), 200, scrollable: find.byType(Scrollable).first);
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
