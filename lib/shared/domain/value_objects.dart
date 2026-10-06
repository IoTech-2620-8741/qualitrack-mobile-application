import 'package:equatable/equatable.dart';

/// Strongly typed identifier of the signed-in user's laboratory.
/// There is intentionally no default value: a missing laboratory must be
/// handled explicitly (configuration happens in QualiTrack Web).
final class LaboratoryId extends Equatable {
  const LaboratoryId(this.value) : assert(value > 0);

  final int value;

  static LaboratoryId? tryCreate(int? raw) =>
      raw != null && raw > 0 ? LaboratoryId(raw) : null;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value.toString();
}
