import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/equipment/presentation/bloc/equipment_list_bloc.dart';
import 'package:qualitrack_mobile/equipment/presentation/screens/equipment_list_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockEquipmentListBloc extends MockBloc<EquipmentListEvent, EquipmentListState> implements EquipmentListBloc {}

void main() {
  late MockEquipmentListBloc bloc;

  setUp(() {
    bloc = MockEquipmentListBloc();
    when(() => bloc.state).thenReturn(
      EquipmentListState(
        remote: RemoteState(
          status: ViewStatus.success,
          data: [
            EquipmentOverview(equipment: equipmentFixture(id: 1, name: 'Chamber A'), environmentName: 'Cold storage'),
            EquipmentOverview(equipment: equipmentFixture(id: 2, name: 'Balance B', deviceType: null)),
          ],
        ),
      ),
    );
  });

  testWidgets('filters through a FAB menu that fits a small phone', (tester) async {
    await tester.pumpLocalized(BlocProvider<EquipmentListBloc>.value(value: bloc, child: const EquipmentListScreen()));

    expect(find.text('SHOWING: ALL'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);

    await tester.tap(find.byTooltip('Filter equipment'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Operational, 2'), findsOneWidget);
    expect(find.bySemanticsLabel('IoT devices, 1'), findsOneWidget);

    // Seven options do not fit above the FAB at 360x640: the farthest one
    // is still reachable by scrolling the menu.
    await tester.scrollUntilVisible(find.bySemanticsLabel('All, 2'), -100, scrollable: find.byType(Scrollable).last);
    expect(find.bySemanticsLabel('All, 2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Operational, 2'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const EquipmentFilterChanged(EquipmentFilter.operational))).called(1);
  });
}
