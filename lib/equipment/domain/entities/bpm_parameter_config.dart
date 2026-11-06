import 'package:equatable/equatable.dart';

/// `BpmParameterConfigResource`: acceptance limits configured in Web.
class BpmParameterConfig extends Equatable {
  const BpmParameterConfig({
    required this.id,
    required this.equipmentId,
    required this.parameterName,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  final int id;
  final int equipmentId;
  final String parameterName;
  final double? minValue;
  final double? maxValue;
  final String? unit;

  /// Case-insensitive match between a telemetry parameter and this limit.
  bool appliesTo(String parameter) =>
      parameterName.trim().toLowerCase() == parameter.trim().toLowerCase();

  bool isWithin(double value) =>
      (minValue == null || value >= minValue!) && (maxValue == null || value <= maxValue!);

  @override
  List<Object?> get props => [id, equipmentId, parameterName, minValue, maxValue, unit];
}
