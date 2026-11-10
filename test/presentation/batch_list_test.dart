import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/application/batch_facade_service.dart';
import 'package:qualitrack_mobile/batch/domain/entities/batch_status.dart';
import 'package:qualitrack_mobile/batch/presentation/batch_list/batch_list_screen.dart';
import 'package:qualitrack_mobile/batch/presentation/batch_list/bloc/bloc.dart';
import 'package:qualitrack_mobile/common/domain/value_objects.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

class MockBatchListBloc extends MockBloc<BatchListEvent, BatchListState> implements BatchListBloc {}

void main() {
  final batches = [
    batchFixture(id: 1, batchNumber: 'LOT-A'),
    batchFixture(id: 2, batchNumber: 'LOT-B', status: BatchStatus.released),
  ];

  blocTest<BatchListBloc, BatchListState>(
    'clearing the filters shows every batch and empties the search',
    build: () {
      final repo = MockBatchRepository();
      when(() => repo.getByLaboratory(const LaboratoryId(7))).thenAnswer((_) async => batches);
      return BatchListBloc(
        batchService: BatchFacadeService(repository: repo),
        laboratoryId: () => const LaboratoryId(7),
      );
    },
    act: (bloc) async {
      bloc.add(const BatchListRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const BatchListFilterChanged(BatchFilter.rejected));
      bloc.add(const BatchListQueryChanged('lot-z'));
      bloc.add(const BatchListFiltersCleared());
    },
    verify: (bloc) {
      expect(bloc.state.filter, BatchFilter.all);
      expect(bloc.state.query, isEmpty);
      expect(bloc.state.clearCount, 1);
      expect(bloc.state.filtered, isFalse);
      // Same start date: the newest batch first.
      expect(bloc.state.visible.map((b) => b.id), [2, 1]);
    },
  );

  group('BatchListScreen', () {
    Future<MockBatchListBloc> pump(WidgetTester tester, BatchListState state) async {
      final bloc = MockBatchListBloc();
      when(() => bloc.state).thenReturn(state);
      await tester.pumpLocalized(BlocProvider<BatchListBloc>.value(value: bloc, child: const BatchListScreen()));
      return bloc;
    }

    BatchListState loaded({BatchFilter filter = BatchFilter.all}) => BatchListState(
      remote: RemoteState(status: ViewStatus.success, data: batches),
      filter: filter,
    );

    testWidgets('the FAB menu filters by status and lists each count', (tester) async {
      final bloc = await pump(tester, loaded());

      expect(find.text('SHOWING: ALL'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      await tester.tap(find.byTooltip('Filter batches'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Released, 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The option, not the "Released" status badge of a batch card.
      await tester.tap(find.bySemanticsLabel('Released, 1'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const BatchListFilterChanged(BatchFilter.released))).called(1);
      expect(find.bySemanticsLabel('Released, 1'), findsNothing);
    });

    testWidgets('the summary card shows the status in use and how many batches match', (tester) async {
      await pump(tester, loaded(filter: BatchFilter.released));

      expect(find.text('SHOWING: RELEASED'), findsOneWidget);
      expect(find.bySemanticsLabel('Showing: Released, 1 of 2'), findsOneWidget);
      expect(find.text('LOT-B'), findsOneWidget);
      expect(find.text('LOT-A'), findsNothing);
    });

    testWidgets('offers to clear the filters when no batch matches', (tester) async {
      final bloc = await pump(tester, loaded(filter: BatchFilter.rejected));

      expect(find.text('LOT-A'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('batch.clearFilters')));
      await tester.tap(find.byKey(const Key('batch.clearFilters')));

      verify(() => bloc.add(const BatchListFiltersCleared())).called(1);
    });
  });
}
