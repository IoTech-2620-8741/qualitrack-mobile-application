import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/equipment/presentation/bloc/equipment_list_bloc.dart';
import 'package:qualitrack_mobile/equipment/presentation/screens/equipment_list_screen.dart';
import 'package:qualitrack_mobile/tracking/api/index.dart';

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
            EquipmentOverview(
              equipment: equipmentFixture(id: 3, name: 'Edge MP', deviceType: null, type: 'EDGE_GATEWAY'),
              environmentName: 'Raw materials',
            ),
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
    expect(find.bySemanticsLabel('Operational, 3'), findsOneWidget);
    expect(find.bySemanticsLabel('IoT devices, 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Edge Gateways, 1'), findsOneWidget);

    // Eight options do not fit above the FAB at 360x640: the farthest one
    // is still reachable by scrolling the menu.
    await tester.scrollUntilVisible(find.bySemanticsLabel('All, 3'), -100, scrollable: find.byType(Scrollable).last);
    expect(find.bySemanticsLabel('All, 3'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Operational, 3'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const EquipmentFilterChanged(EquipmentFilter.operational))).called(1);
  });

  testWidgets('names an Edge Gateway instead of showing its type code', (tester) async {
    await tester.pumpLocalized(BlocProvider<EquipmentListBloc>.value(value: bloc, child: const EquipmentListScreen()));

    expect(find.text('Edge MP'), findsOneWidget);
    expect(find.text('Edge Gateway'), findsOneWidget);
    expect(find.textContaining('EDGE_GATEWAY'), findsNothing);
    expect(find.byIcon(Icons.router_outlined), findsWidgets);
  });

  testWidgets('counts a single piece of equipment in the singular', (tester) async {
    when(() => bloc.state).thenReturn(
      EquipmentListState(
        remote: RemoteState(
          status: ViewStatus.success,
          data: [
            EquipmentOverview(
              equipment: equipmentFixture(),
              connection: const DeviceConnection(deviceId: 10, status: ConnectionStatus.requiresReview),
            ),
          ],
        ),
      ),
    );
    final screen = BlocProvider<EquipmentListBloc>.value(value: bloc, child: const EquipmentListScreen());

    await tester.pumpLocalized(screen);
    expect(find.text('1 registered · 1 needs attention'), findsOneWidget);

    await tester.pumpLocalized(screen, locale: const Locale('es'));
    expect(find.text('1 registrado · 1 requiere atención'), findsOneWidget);
  });

  test('the Edge Gateways filter keeps only the gateways', () {
    final state = bloc.state.copyWith(filter: EquipmentFilter.edgeGateways);
    expect(state.visible.map((item) => item.equipment.name), ['Edge MP']);
    expect(state.countFor(EquipmentFilter.iotDevices), 1);
  });
}
