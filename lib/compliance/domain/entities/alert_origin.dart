/// Where the deviation was detected: the environmental device of an
/// environment or a container monitor.
enum AlertOrigin {
  environment('ENVIRONMENT'),
  container('CONTAINER'),
  unknown('UNKNOWN');

  const AlertOrigin(this.code);

  final String code;

  static AlertOrigin fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertOrigin.unknown;
  }
}
