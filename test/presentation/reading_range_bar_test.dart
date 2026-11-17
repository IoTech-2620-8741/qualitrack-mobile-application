import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_state.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/metric_threshold.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/monitored_metric.dart';
import 'package:qualitrack_mobile/tracking/presentation/widgets/reading_range_bar.dart';

import '../helpers/pump_app.dart';

const _temperature = MetricThreshold(
  metric: MonitoredMetric.temperature,
  unit: '°C',
  normalMin: 15,
  normalMax: 30,
  criticalMin: 10,
  criticalMax: 36,
);

List<EnvironmentalState> _states(ReadingRangeScale scale) => [for (final zone in scale.zones) zone.state];

void main() {
  group('ReadingRangeScale', () {
    test('places the zones from critical to normal and back, and the reading among them', () {
      final scale = ReadingRangeScale.of(_temperature, 20.5)!;

      expect(_states(scale), [
        EnvironmentalState.critical,
        EnvironmentalState.warning,
        EnvironmentalState.normal,
        EnvironmentalState.warning,
        EnvironmentalState.critical,
      ]);
      // From 7.4 to 38.6: the bounds and a tenth of their span on each side.
      expect(scale.zones[2].start, closeTo(7.6 / 31.2, 0.001));
      expect(scale.zones[2].end, closeTo(22.6 / 31.2, 0.001));
      expect(scale.position, closeTo(13.1 / 31.2, 0.001));
    });

    test('keeps a reading beyond the critical bound on the bar, in its last zone', () {
      final scale = ReadingRangeScale.of(_temperature, 40)!;

      expect(scale.position, lessThan(1));
      expect(scale.position, greaterThan(scale.zones.last.start));
    });

    test('starts at zero when there is no lower bound and the reading is not negative', () {
      const luminosity = MetricThreshold(
        metric: MonitoredMetric.luminosity,
        unit: 'lux',
        normalMax: 300,
        criticalMax: 500,
      );

      final scale = ReadingRangeScale.of(luminosity, 10)!;

      expect(_states(scale), [EnvironmentalState.normal, EnvironmentalState.warning, EnvironmentalState.critical]);
      expect(scale.zones.first.start, 0);
      expect(scale.zones.first.end, closeTo(300 / 549, 0.001));
      expect(scale.position, closeTo(10 / 549, 0.001));
    });

    test('draws nothing without a normal range', () {
      const onlyCritical = MetricThreshold(metric: MonitoredMetric.temperature, criticalMin: 0, criticalMax: 40);

      expect(ReadingRangeScale.of(onlyCritical, 20), isNull);
    });
  });

  testWidgets('the bar is a short strip that the screen reader skips', (tester) async {
    await tester.pumpLocalized(
      Scaffold(
        body: ReadingRangeBar(
          scale: ReadingRangeScale.of(_temperature, 20.5)!,
          state: EnvironmentalState.normal,
        ),
      ),
    );

    expect(tester.getSize(find.byType(ReadingRangeBar)).height, ReadingRangeBar.height);
    expect(
      find.descendant(of: find.byType(ReadingRangeBar), matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );
  });
}
