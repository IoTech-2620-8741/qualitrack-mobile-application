import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/batch/domain/entities/batch_status.dart';
import 'package:qualitrack_mobile/batch/domain/entities/production_batch.dart';

import '../helpers/fixtures.dart';

void main() {
  group('ProductionBatch.firstDecisionDay', () {
    final today = DateTime(2026, 11, 8, 13, 30);

    ProductionBatch startingOn(String? startDate) => ProductionBatch(
      id: 3,
      labId: 7,
      productId: 1,
      batchNumber: 'LOT-2026-123',
      status: BatchStatus.pending,
      startDate: startDate,
    );

    test('a decision cannot be dated before the batch started', () {
      expect(batchFixture().firstDecisionDay(today), DateTime(2026, 9, 4));
    });

    test('a batch that starts later can still be decided today', () {
      expect(startingOn('2026-12-01').firstDecisionDay(today), DateTime(2026, 11, 8));
    });

    test('without a start date the calendar goes back five years', () {
      expect(startingOn(null).firstDecisionDay(today), DateTime(2021, 11, 8));
    });
  });
}
