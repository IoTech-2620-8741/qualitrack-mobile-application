enum AlertStatus {
  unresolved('UNRESOLVED'),
  acknowledged('ACKNOWLEDGED'),
  resolved('RESOLVED'),
  unknown('UNKNOWN');

  const AlertStatus(this.code);

  final String code;

  static AlertStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertStatus.unknown;
  }
}
