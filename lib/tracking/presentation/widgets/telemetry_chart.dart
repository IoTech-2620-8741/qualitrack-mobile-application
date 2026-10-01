import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../domain/telemetry.dart';

/// Line chart of real telemetry history points. Anomalies are drawn as larger
/// red dots and BPM limits (if configured in Web) as dashed lines.
class TelemetryChart extends StatelessWidget {
  const TelemetryChart({super.key, required this.points, this.limit, this.unit});

  final List<TelemetryHistoryPoint> points;
  final BpmParameterConfig? limit;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (points.isEmpty) {
      return SizedBox(
        height: 200,
        child: EmptyView(title: l10n.noHistoryInRange, icon: Icons.show_chart),
      );
    }
    final locale = Localizations.localeOf(context).languageCode;
    final spots = [
      for (final p in points)
        FlSpot(p.timestamp!.millisecondsSinceEpoch.toDouble(), p.recordedValue),
    ];
    final values = [
      ...points.map((p) => p.recordedValue),
      if (limit?.minValue != null) limit!.minValue!,
      if (limit?.maxValue != null) limit!.maxValue!,
    ];
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    final pad = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY) * 0.1;
    minY -= pad;
    maxY += pad;
    final minX = spots.first.x;
    var maxX = spots.last.x;
    if (maxX <= minX) maxX = minX + 60000;
    final timeFormat = DateFormat.Hm(locale);
    final anomalies = {for (final p in points) p.timestamp!.millisecondsSinceEpoch.toDouble(): p.isAnomaly};

    return Semantics(
      label: l10n.chartSemantics(points.length, unit ?? ''),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) => Text(
                    NumberFormat.compact(locale: locale).format(value),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (maxX - minX) / 3,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      timeFormat.format(DateTime.fromMillisecondsSinceEpoch(value.toInt())),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (limit?.minValue != null) _limitLine(limit!.minValue!),
                if (limit?.maxValue != null) _limitLine(limit!.maxValue!),
              ],
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.navy,
                getTooltipItems: (touched) => [
                  for (final spot in touched)
                    LineTooltipItem(
                      '${NumberFormat.decimalPattern(locale).format(spot.y)} ${unit ?? ''}\n'
                      '${DateFormat.MMMd(locale).add_Hms().format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.chartLine,
                barWidth: 2.5,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.chartLine.withValues(alpha: 0.12),
                ),
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, bar) => anomalies[spot.x] ?? false,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.chartAnomaly,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  HorizontalLine _limitLine(double y) => HorizontalLine(
    y: y,
    color: AppColors.chartLimit,
    strokeWidth: 1.5,
    dashArray: const [6, 4],
  );
}
