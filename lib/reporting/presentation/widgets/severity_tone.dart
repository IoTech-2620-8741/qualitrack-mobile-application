/// This file contains presentation extensions and helpers for the Reporting context.
///
/// It maps domain enums (like TrendDirection and DeviationSeverity) to
/// visual elements (like Icons and BadgeTones) used in the UI.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/reporting_enums.dart';

/// Extension to provide an icon for each [TrendDirection].
extension TrendDirectionPresentation on TrendDirection {
  /// Returns the appropriate arrow icon based on the trend direction.
  IconData get icon => switch (this) {
    TrendDirection.increasing => Icons.trending_up,
    TrendDirection.decreasing => Icons.trending_down,
    TrendDirection.stable => Icons.trending_flat,
    TrendDirection.unknown => Icons.remove,
  };
}

/// Maps a [DeviationSeverity] to a specific [BadgeTone] for color-coding.
///
/// Used to paint the status badges in green (onTrack),
/// yellow (warning), red (critical), or grey (noData).
BadgeTone timeInRangeToneFromSeverity(DeviationSeverity severity) =>
    switch (severity) {
      DeviationSeverity.critical => BadgeTone.critical,
      DeviationSeverity.warning => BadgeTone.warning,
      DeviationSeverity.onTrack => BadgeTone.success,
      DeviationSeverity.noData => BadgeTone.neutral,
    };