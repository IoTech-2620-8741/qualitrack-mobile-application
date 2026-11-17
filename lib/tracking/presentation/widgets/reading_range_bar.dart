import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/metric_threshold.dart';
import 'telemetry_labels.dart';

/// A stretch of a [ReadingRangeScale], from 0 (left) to 1 (right), with the
/// state a reading inside it gets.
typedef RangeZone = ({double start, double end, EnvironmentalState state});

/// Where the zones of a threshold and one reading fall on a bar from 0 to 1.
///
/// The bar covers the configured bounds and the reading with a margin around
/// them. Without a lower bound it starts at 0 for readings that cannot be
/// negative, such as lux or ppm.
class ReadingRangeScale {
  const ReadingRangeScale._(this.zones, this.position);

  /// Critical, warning and normal zones from left to right.
  final List<RangeZone> zones;

  /// Where the reading falls, from 0 to 1.
  final double position;

  /// Null when the threshold has no normal range to draw.
  static ReadingRangeScale? of(MetricThreshold threshold, double value) {
    final normalMin = threshold.normalMin;
    final normalMax = threshold.normalMax;
    if (normalMin == null && normalMax == null) return null;
    final criticalMin = threshold.criticalMin;
    final criticalMax = threshold.criticalMax;
    final points = [criticalMin, normalMin, normalMax, criticalMax, value].whereType<double>().toList();
    final lowest = points.reduce(math.min);
    final highest = points.reduce(math.max);
    final span = highest > lowest ? highest - lowest : math.max(highest.abs(), 1.0);
    final margin = span * 0.1;
    final noLowerBound = normalMin == null && criticalMin == null;
    final start = noLowerBound && lowest >= 0 ? 0.0 : lowest - margin;
    final end = highest + margin;
    double at(double bound) => ((bound - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return ReadingRangeScale._([
      if (criticalMin != null) (start: 0.0, end: at(criticalMin), state: EnvironmentalState.critical),
      if (normalMin != null)
        (start: criticalMin == null ? 0.0 : at(criticalMin), end: at(normalMin), state: EnvironmentalState.warning),
      (
        start: normalMin == null ? 0.0 : at(normalMin),
        end: normalMax == null ? 1.0 : at(normalMax),
        state: EnvironmentalState.normal,
      ),
      if (normalMax != null)
        (start: at(normalMax), end: criticalMax == null ? 1.0 : at(criticalMax), state: EnvironmentalState.warning),
      if (criticalMax != null) (start: at(criticalMax), end: 1.0, state: EnvironmentalState.critical),
    ], at(value));
  }
}

/// A bar with the normal (green), warning (amber) and critical (red) zones of
/// a threshold and a mark where the reading is, so the margin left is seen at
/// a glance. The figures are written next to it, so the bar adds nothing to
/// the screen reader.
class ReadingRangeBar extends StatelessWidget {
  const ReadingRangeBar({super.key, required this.scale, required this.state});

  final ReadingRangeScale scale;

  /// State of the reading; a deviation draws the mark in its color.
  final EnvironmentalState state;

  static const double height = 16;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _RangeBarPainter(scale, state)),
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  _RangeBarPainter(this.scale, this.state);

  final ReadingRangeScale scale;
  final EnvironmentalState state;

  static const double _trackHeight = 8;
  static const double _markRadius = 7;
  static const double _markStroke = 3;

  static Color _zoneColor(EnvironmentalState state) => switch (state) {
    EnvironmentalState.critical => AppColors.chartCritical.withValues(alpha: 0.35),
    EnvironmentalState.warning => AppColors.chartWarning.withValues(alpha: 0.45),
    EnvironmentalState.normal || EnvironmentalState.unknown => AppColors.chartNormalRange.withValues(alpha: 0.35),
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
        Paint()..color = _zoneColor(zone.state),
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
          ..color = state.isDeviation ? state.tone.foreground : AppColors.navy,
      );
  }

  @override
  bool shouldRepaint(_RangeBarPainter oldDelegate) => oldDelegate.scale != scale || oldDelegate.state != state;
}
