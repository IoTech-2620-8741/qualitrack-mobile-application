import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:qualitrack_mobile/inventory/presentation/screens/inventory_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockInventoryBloc extends MockBloc<InventoryEvent, InventoryState> implements InventoryBloc {}

void main() {
  late MockInventoryBloc bloc;

  setUp(() {
    bloc = MockInventoryBloc();
    when(() => bloc.state).thenReturn(
      InventoryState(
        remote: RemoteState(
          status: ViewStatus.success,
          data: [
            materialFixture(name: 'Hierro'),
            materialFixture(id: 2, name: 'Lactosa', usable: 10, stockStatus: 'OK'),
          ],
        ),
        environmentNames: const {3: 'Cold storage'},
      ),
    );
  });

  testWidgets('filters the stock through a FAB menu with a summary card', (tester) async {
    await tester.pumpLocalized(BlocProvider<InventoryBloc>.value(value: bloc, child: const InventoryScreen()));

    expect(find.text('SHOWING: ALL'), findsOneWidget);
    expect(find.bySemanticsLabel('Showing: All, 2 of 2'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Filter materials'));
    await tester.pumpAndSettle();
    // "Hierro" is below its minimum and has blocked stock (3 usable of 10 physical).
    expect(find.bySemanticsLabel('Below minimum, 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Blocked stock, 1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Below minimum, 1'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InventoryFilterChanged(InventoryFilter.belowMinimum))).called(1);
  });

  testWidgets('counts a single material in the singular', (tester) async {
    when(() => bloc.state).thenReturn(
      InventoryState(remote: RemoteState(status: ViewStatus.success, data: [materialFixture()])),
    );
    final screen = BlocProvider<InventoryBloc>.value(value: bloc, child: const InventoryScreen());

    await tester.pumpLocalized(screen);
    expect(find.text('1 material'), findsOneWidget);

    await tester.pumpLocalized(screen, locale: const Locale('es'));
    expect(find.text('1 material'), findsOneWidget);
  });
}
