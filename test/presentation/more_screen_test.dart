import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/app/router/more_screen.dart';
import 'package:qualitrack_mobile/iam/domain/entities/user_role.dart';
import 'package:qualitrack_mobile/profile/application/profile_facade_service.dart';
import 'package:qualitrack_mobile/profile/presentation/bloc/current_profile_controller.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  late CurrentProfileController profile;

  setUp(() => profile = CurrentProfileController(profileService: ProfileFacadeService(repository: MockProfileRepository())));

  Future<int Function()> pump(WidgetTester tester) async {
    var signOuts = 0;
    await tester.pumpLocalized(
      MoreScreen(session: sessionFixture(), currentProfile: profile, onSignOut: () async => signOuts++),
      size: const Size(390, 844),
    );
    return () => signOuts;
  }

  testWidgets('groups the destinations in sections without overflow', (tester) async {
    await pump(tester);

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Quality'), findsOneWidget);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    // Quality managers see the subscription, as in Web.
    expect(find.text('Subscription'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Order of the Web menu; telemetry, alerts and batches are tabs.
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Products'), lessThan(top('Equipment')));
    expect(top('Equipment'), lessThan(top('Inventory')));
    expect(find.text('Compliance alerts'), findsNothing);
    expect(top('Operations'), lessThan(top('Quality')));
    expect(top('Quality'), lessThan(top('Administration')));
  });

  testWidgets('hides the administration section from other roles', (tester) async {
    await tester.pumpLocalized(
      MoreScreen(
        session: sessionFixture(roles: const [UserRole.labOperator]),
        currentProfile: profile,
        onSignOut: () async {},
      ),
      size: const Size(390, 844),
    );

    expect(find.text('Administration'), findsNothing);
    expect(find.text('Subscription'), findsNothing);
    expect(find.text('Quality'), findsOneWidget);
  });

  testWidgets('signs out with the profile button, only after confirming', (tester) async {
    final signOuts = await pump(tester);

    await tester.scrollUntilVisible(find.byKey(const Key('more.signOut')), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'Sign out'), findsOneWidget);

    await tester.tap(find.byKey(const Key('more.signOut')));
    await tester.pumpAndSettle();
    expect(signOuts(), 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(signOuts(), 1);
  });
}
