import 'package:equatable/equatable.dart';

import 'measurement.dart';

/// Latest reading of one metric (one card in the dashboard).
class MetricReading extends Equatable {
  const MetricReading({required this.latest, required this.samples});

  final Measurement latest;
  final int samples;

  @override
  List<Object?> get props => [latest, samples];
}
