import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alert_detail_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/alerts_bloc.dart';
import 'package:qualitrack_mobile/compliance/presentation/pages/alert_detail_page.dart';
import 'package:qualitrack_mobile/compliance/presentation/pages/alerts_page.dart';
import 'package:qualitrack_mobile/iam/presentation/bloc/sign_in_bloc.dart';
import 'package:qualitrack_mobile/iam/presentation/pages/sign_in_page.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/presentation/remote_state.dart';
import 'package:qualitrack_mobile/shared/presentation/view_status.dart';
import 'package:qualitrack_mobile/shared/presentation/widgets/state_views.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockSignInBloc extends MockBloc<SignInEvent, SignInState> implements SignInBloc {}

class MockAlertsBloc extends MockBloc<AlertsEvent, AlertsState> implements AlertsBloc {}

class MockAlertDetailBloc extends MockBloc<AlertDetailEvent, AlertDetailState>
    implements AlertDetailBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue<SignInEvent>(const SignInSubmitted(username: '', password: ''));
    registerFallbackValue<AlertsEvent>(const AlertsRequested());
    registerFallbackValue<AlertDetailEvent>(const AlertDetailRequested());
  });

  group('Sign In', () {
    late MockSignInBloc bloc;

    setUp(() {
      bloc = MockSignInBloc();
      when(() => bloc.state).thenReturn(const SignInState());
    });

    Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) =>
        tester.pumpLocalized(
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

    testWidgets('shows loading and backend errors', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable(const [
          SignInState(status: SignInStatus.submitting),
          SignInState(status: SignInStatus.failure, failure: NetworkFailure()),
        ]),
        initialState: const SignInState(),
      );
      await pump(tester);
      await tester.pump();
      expect(find.textContaining('No connection to QualiTrack'), findsOneWidget);
    });

    testWidgets('is localized in Spanish', (tester) async {
      await pump(tester, locale: const Locale('es'));
      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Usuario'), findsOneWidget);
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
        Scaffold(
          body: ErrorView(failure: const TimeoutFailure(), onRetry: () => retried = true),
        ),
      );
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('took too long'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('Alerts list', () {
    testWidgets('renders counters and alert cards without overflow at 360x640', (tester) async {
      final bloc = MockAlertsBloc();
      when(() => bloc.state).thenReturn(
        AlertsState(
          remote: RemoteState(
            status: ViewStatus.success,
            data: AlertsData(
              alerts: [
                alertFixture(id: 1),
                alertFixture(id: 2, status: AlertStatus.resolved, severity: AlertSeverity.low),
              ],
              equipmentNames: const {10: 'Stability Chamber with a very long descriptive name'},
            ),
          ),
        ),
      );

      await tester.pumpLocalized(
        BlocProvider<AlertsBloc>.value(value: bloc, child: const AlertsPage()),
      );

      expect(find.text('Compliance Alerts'), findsWidgets);
      expect(find.text('Temperature'), findsWidgets);
      expect(find.textContaining('38.6'), findsWidgets);
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
          equipmentName: 'Stability Chamber',
        ),
      );
    });

    Future<void> pump(WidgetTester tester, {required bool canReview}) => tester.pumpLocalized(
      BlocProvider<AlertDetailBloc>.value(
        value: bloc,
        child: AlertDetailPage(canReview: canReview),
      ),
      size: const Size(390, 844),
    );

    testWidgets('QA manager can acknowledge after confirming', (tester) async {
      await pump(tester, canReview: true);
      await tester.scrollUntilVisible(
        find.byKey(const Key('alert.acknowledge')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('alert.acknowledge')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const AlertAcknowledgeSubmitted())).called(1);
    });

    testWidgets('resolve requires notes', (tester) async {
      await pump(tester, canReview: true);
      await tester.scrollUntilVisible(
        find.byKey(const Key('alert.resolve')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('alert.resolve')));
      await tester.pump();
      expect(find.text('Resolution notes are required'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<AlertResolveSubmitted>())));
    });

    testWidgets('lab operator sees no review actions', (tester) async {
      await pump(tester, canReview: false);
      expect(find.byKey(const Key('alert.acknowledge')), findsNothing);
      expect(find.byKey(const Key('alert.resolve')), findsNothing);
      expect(find.textContaining('available to QA Managers'), findsOneWidget);
    });
  });
}
