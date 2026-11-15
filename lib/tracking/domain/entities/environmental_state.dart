/// `EnvironmentalState`: how a reading was evaluated in Cloud against the
/// profile that was in force.
enum EnvironmentalState {
  normal('NORMAL'),
  warning('WARNING'),
  critical('CRITICAL'),
  unknown('');

  const EnvironmentalState(this.code);

  final String code;

  bool get isDeviation => this == warning || this == critical;

  static EnvironmentalState fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return EnvironmentalState.unknown;
  }
}
