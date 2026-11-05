import 'package:flutter/material.dart';
import '../../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/entities/reporting_entities.dart';

extension TrendDirectionPresentation on TrendDirection {
  IconData get icon => switch (this) {
    TrendDirection.increasing => Icons.trending_up,
    TrendDirection.decreasing => Icons.trending_down,
    TrendDirection.stable => Icons.trending_flat,
    TrendDirection.unknown => Icons.remove,
  };
}

BadgeTone timeInRangeToneFromSeverity(DeviationSeverity severity) =>
    switch (severity) {
      DeviationSeverity.critical => BadgeTone.critical,
      DeviationSeverity.warning => BadgeTone.warning,
      DeviationSeverity.onTrack => BadgeTone.success,
      DeviationSeverity.noData => BadgeTone.neutral,
    };