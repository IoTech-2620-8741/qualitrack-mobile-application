import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';

/// Where the normal band starts and ends and where [value] lies, as fractions
/// of a bar that holds the three with a margin. An open side of the band
/// reaches the edge. No zero is assumed, so a −18 °C freezer reads as well as
/// a 2–8 °C fridge.
({double bandStart, double bandEnd, double marker}) rangeBarStops({
  double? normalMin,
  double? normalMax,
  required double value,
}) {
  final points = [if (normalMin != null) normalMin, if (normalMax != null) normalMax, value];
  final start = points.reduce(math.min);
  final end = points.reduce(math.max);
  final pad = end == start ? 1.0 : (end - start) / 4;
  final low = start - pad;
  final high = end + pad;
  double at(double x) => (x - low) / (high - low);
  return (
    bandStart: normalMin == null ? 0.0 : at(normalMin),
    bandEnd: normalMax == null ? 1.0 : at(normalMax),
    marker: at(value),
  );
}

/// The normal range of a metric as a green band on a grey track, and the
/// reading as a dot in [color]: how far out of range it is, at a glance. The
/// text beside it says the same to a screen reader.
class RangeBar extends StatelessWidget {
  const RangeBar({super.key, this.normalMin, this.normalMax, required this.value, required this.color});

  final double? normalMin;
  final double? normalMax;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final stops = rangeBarStops(normalMin: normalMin, normalMax: normalMax, value: value);
    return ExcludeSemantics(
      child: SizedBox(
        height: 12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.border, borderRadius: AppRadius.pillAll),
                ),
                Positioned(
                  left: width * stops.bandStart,
                  // A profile whose minimum is above its maximum draws no band.
                  width: width * math.max(0, stops.bandEnd - stops.bandStart),
                  top: 3,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.successBase.withValues(alpha: 0.5),
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
                Positioned(
                  left: width * stops.marker - 6,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
