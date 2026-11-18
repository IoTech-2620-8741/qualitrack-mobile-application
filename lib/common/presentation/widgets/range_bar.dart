import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'status_badge.dart';

/// What a value inside a zone of a [RangeScale] is: within the normal range,
/// between a normal and a critical bound, or past a critical bound.
enum RangeZoneKind { normal, warning, critical }

/// A stretch of a [RangeScale], from 0 (left) to 1 (right).
typedef RangeZone = ({double start, double end, RangeZoneKind kind});

/// Where the zones of a range and one value fall on a bar from 0 to 1.
///
/// The bar covers the bounds and the value with a margin around them. Any
/// bound may be missing, and a missing side is open. Without a lower bound the
/// bar starts at 0 for values that cannot be negative, such as lux or ppm;
/// otherwise no zero is assumed, so a −18 °C freezer reads as well as a
/// 2–8 °C fridge.
class RangeScale {
  const RangeScale._(this.zones, this.position);

  /// Critical, warning and normal zones from left to right.
  final List<RangeZone> zones;

  /// Where the value falls, from 0 to 1.
  final double position;

  /// Null without a normal range to draw.
  static RangeScale? of({
    double? normalMin,
    double? normalMax,
    double? criticalMin,
    double? criticalMax,
    required double value,
  }) {
    if (normalMin == null && normalMax == null) return null;
    final points = [criticalMin, normalMin, normalMax, criticalMax, value].whereType<double>().toList();
    final lowest = points.reduce(math.min);
    final highest = points.reduce(math.max);
    final span = highest > lowest ? highest - lowest : math.max(highest.abs(), 1.0);
    final margin = span * 0.1;
    final noLowerBound = normalMin == null && criticalMin == null;
    final start = noLowerBound && lowest >= 0 ? 0.0 : lowest - margin;
    final end = highest + margin;
    double at(double bound) => ((bound - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return RangeScale._([
      if (criticalMin != null) (start: 0.0, end: at(criticalMin), kind: RangeZoneKind.critical),
      if (normalMin != null)
        (start: criticalMin == null ? 0.0 : at(criticalMin), end: at(normalMin), kind: RangeZoneKind.warning),
      (
        start: normalMin == null ? 0.0 : at(normalMin),
        end: normalMax == null ? 1.0 : at(normalMax),
        kind: RangeZoneKind.normal,
      ),
      if (normalMax != null)
        (start: at(normalMax), end: criticalMax == null ? 1.0 : at(criticalMax), kind: RangeZoneKind.warning),
      if (criticalMax != null) (start: at(criticalMax), end: 1.0, kind: RangeZoneKind.critical),
    ], at(value));
  }
}

/// A bar with the normal (green), warning (amber) and critical (red) zones of
/// a range and a mark where the value is, so the margin left is seen at a
/// glance. Telemetry, the Home panel and the alerts draw it with their own
/// data. The figures are written next to it, so the bar adds nothing to the
/// screen reader.
class RangeBar extends StatelessWidget {
  const RangeBar({super.key, required this.scale, this.markTone});

  final RangeScale scale;

  /// Color of the mark for a value out of range; null draws it in navy.
  final BadgeTone? markTone;

  static const double height = 16;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _RangeBarPainter(scale, markTone?.foreground ?? AppColors.navy)),
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  _RangeBarPainter(this.scale, this.markColor);

  final RangeScale scale;
  final Color markColor;

  static const double _trackHeight = 8;
  static const double _markRadius = 7;
  static const double _markStroke = 3;

  static Color _zoneColor(RangeZoneKind kind) => switch (kind) {
    RangeZoneKind.critical => AppColors.chartCritical.withValues(alpha: 0.35),
    RangeZoneKind.warning => AppColors.chartWarning.withValues(alpha: 0.45),
    RangeZoneKind.normal => AppColors.chartNormalRange.withValues(alpha: 0.35),
  };

  @override
  void paint(Canvas canvas, Size size) {
    // The track leaves room for the mark at both ends.
    const left = _markRadius;
    final width = math.max(size.width - 2 * _markRadius, 0.0);
    final top = (size.height - _trackHeight) / 2;
    final track = RRect.fromLTRBR(left, top, left + width, top + _trackHeight, const Radius.circular(_trackHeight / 2));
    canvas
      ..save()
      ..clipRRect(track);
    for (final zone in scale.zones) {
      if (zone.end <= zone.start) continue;
      canvas.drawRect(
        Rect.fromLTRB(left + zone.start * width, top, left + zone.end * width, top + _trackHeight),
        Paint()..color = _zoneColor(zone.kind),
      );
    }
    canvas.restore();

    final center = Offset(left + scale.position * width, size.height / 2);
    canvas
      ..drawCircle(center, _markRadius, Paint()..color = AppColors.surface)
      ..drawCircle(
        center,
        _markRadius - _markStroke / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _markStroke
          ..color = markColor,
      );
  }

  @override
  bool shouldRepaint(_RangeBarPainter oldDelegate) => oldDelegate.scale != scale || oldDelegate.markColor != markColor;
}
