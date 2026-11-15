enum AlertSeverity {
  low('LOW'),
  warning('WARNING'),
  critical('CRITICAL'),
  unknown('UNKNOWN');

  const AlertSeverity(this.code);

  final String code;

  static AlertSeverity fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertSeverity.unknown;
  }
}
