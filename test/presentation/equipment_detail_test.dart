import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/application/section.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/equipment/presentation/bloc/equipment_detail_bloc.dart';
import 'package:qualitrack_mobile/equipment/presentation/screens/equipment_detail_screen.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/deviation_entities.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/reporting_enums.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockEquipmentDetailBloc extends MockBloc<EquipmentDetailRequested, RemoteState<EquipmentDetail>>
    implements EquipmentDetailBloc {}

void main() {
  testWidgets('counts a single deviation of a variable in the singular', (tester) async {
    final bloc = MockEquipmentDetailBloc();
    when(() => bloc.state).thenReturn(
      RemoteState(
        status: ViewStatus.success,
        data: EquipmentDetail(
          equipment: equipmentFixture(),
          trends: const Section([
            DeviationTrend(
              parameterName: 'TEMPERATURE',
              equipmentId: 10,
              direction: TrendDirection.stable,
              evaluatedReadings: 12,
              deviationCount: 1,
              criticalDeviationCount: 1,
            ),
          ]),
        ),
      ),
    );
    final screen = BlocProvider<EquipmentDetailBloc>.value(
      value: bloc,
      child: const EquipmentDetailScreen(currentUserId: 42),
    );

    await tester.pumpLocalized(screen);
    expect(find.text('1 deviation · 1 critical'), findsOneWidget);

    await tester.pumpLocalized(screen, locale: const Locale('es'));
    expect(find.text('1 desviación · 1 crítica'), findsOneWidget);
  });
}
