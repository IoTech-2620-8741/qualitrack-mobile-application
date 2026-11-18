import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/range_bar.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/status_badge.dart';

import '../helpers/pump_app.dart';

/// A temperature range: normal 15–30 °C, critical below 10 °C and above 36 °C.
RangeScale? _temperature(double value) =>
    RangeScale.of(normalMin: 15, normalMax: 30, criticalMin: 10, criticalMax: 36, value: value);

List<RangeZoneKind> _kinds(RangeScale scale) => [for (final zone in scale.zones) zone.kind];

void main() {
  group('RangeScale', () {
    test('places the zones from critical to normal and back, and the value among them', () {
      final scale = _temperature(20.5)!;

      expect(_kinds(scale), [
        RangeZoneKind.critical,
        RangeZoneKind.warning,
        RangeZoneKind.normal,
        RangeZoneKind.warning,
        RangeZoneKind.critical,
      ]);
      // From 7.4 to 38.6: the bounds and a tenth of their span on each side.
      expect(scale.zones[2].start, closeTo(7.6 / 31.2, 0.001));
      expect(scale.zones[2].end, closeTo(22.6 / 31.2, 0.001));
      expect(scale.position, closeTo(13.1 / 31.2, 0.001));
    });

    test('keeps a value beyond the critical bound on the bar, in its last zone', () {
      final scale = _temperature(40)!;

      expect(scale.position, lessThan(1));
      expect(scale.position, greaterThan(scale.zones.last.start));
    });

    test('starts at zero when there is no lower bound and the value is not negative', () {
      final scale = RangeScale.of(normalMax: 300, criticalMax: 500, value: 10)!;

      expect(_kinds(scale), [RangeZoneKind.normal, RangeZoneKind.warning, RangeZoneKind.critical]);
      expect(scale.zones.first.start, 0);
      expect(scale.zones.first.end, closeTo(300 / 549, 0.001));
      expect(scale.position, closeTo(10 / 549, 0.001));
    });

    test('assumes no zero below a freezer range', () {
      final scale = RangeScale.of(normalMax: -18, value: -15)!;

      expect(_kinds(scale), [RangeZoneKind.normal, RangeZoneKind.warning]);
      // From −18.3 to −14.7.
      expect(scale.zones.first.end, closeTo(0.3 / 3.6, 0.001));
      expect(scale.position, closeTo(3.3 / 3.6, 0.001));
    });

    test('draws a normal range without critical bounds as normal and warning zones', () {
      final scale = RangeScale.of(normalMin: 2, normalMax: 8, value: 9.6)!;

      expect(_kinds(scale), [RangeZoneKind.warning, RangeZoneKind.normal, RangeZoneKind.warning]);
      expect(scale.zones.first.start, 0);
      expect(scale.zones.last.end, 1);
    });

    test('draws nothing without a normal range', () {
      expect(RangeScale.of(criticalMin: 0, criticalMax: 40, value: 20), isNull);
    });
  });

  testWidgets('the bar is a short strip that the screen reader skips', (tester) async {
    await tester.pumpLocalized(
      Scaffold(body: RangeBar(scale: _temperature(38.6)!, markTone: BadgeTone.critical)),
    );

    expect(tester.getSize(find.byType(RangeBar)).height, RangeBar.height);
    expect(
      find.descendant(of: find.byType(RangeBar), matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
