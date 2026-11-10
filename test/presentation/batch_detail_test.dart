import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/entities/batch_status.dart';
import 'package:qualitrack_mobile/batch/domain/entities/batch_traceability.dart';
import 'package:qualitrack_mobile/batch/presentation/batch_detail/batch_detail_screen.dart';
import 'package:qualitrack_mobile/batch/presentation/batch_detail/bloc/bloc.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockBatchDetailBloc extends MockBloc<BatchDetailEvent, BatchDetailState> implements BatchDetailBloc {}

void main() {
  late MockBatchDetailBloc bloc;

  void loaded(BatchStatus status) => when(() => bloc.state).thenReturn(
    BatchDetailState(
      detail: RemoteState(
        status: ViewStatus.success,
        data: BatchDetail(
          traceability: BatchTraceability(
            batch: batchFixture(id: 7, status: status),
            equipment: const [BatchEquipmentUsage(equipmentId: 10, equipmentName: 'Granulator')],
          ),
        ),
      ),
    ),
  );

  setUp(() => bloc = MockBatchDetailBloc());

  Future<void> pump(WidgetTester tester, {required bool canReview}) => tester.pumpLocalized(
    BlocProvider<BatchDetailBloc>.value(
      value: bloc,
      child: BatchDetailScreen(canReview: canReview, currentUserId: 42),
    ),
    size: const Size(390, 844),
  );

  testWidgets('quality managers decide from a fixed bar while the batch awaits review', (tester) async {
    loaded(BatchStatus.inProgress);
    await pump(tester, canReview: true);

    expect(find.byKey(const Key('batch.release')), findsOneWidget);
    expect(find.byKey(const Key('batch.reject')), findsOneWidget);
    // The summary shows where the batch is in its cycle and what it used.
    expect(find.text('Batch cycle'), findsOneWidget);
    expect(find.bySemanticsLabel('Equipment: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no decision bar once the batch is released', (tester) async {
    loaded(BatchStatus.released);
    await pump(tester, canReview: true);

    expect(find.byKey(const Key('batch.release')), findsNothing);
  });

  testWidgets('other roles read the batch without the decision bar', (tester) async {
    loaded(BatchStatus.pending);
    await pump(tester, canReview: false);

    expect(find.byKey(const Key('batch.release')), findsNothing);
    expect(find.text('Only the quality manager releases or rejects batches.'), findsOneWidget);
  });
}
