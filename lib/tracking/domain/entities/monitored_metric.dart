/// `MonitoredMetric` of Tracking & Telemetry. Environmental devices measure
/// air quality and motion; container monitors measure temperature, humidity,
/// luminosity and read RFID tags.
enum MonitoredMetric {
  airQuality('AIR_QUALITY'),
  motion('MOTION'),
  temperature('TEMPERATURE'),
  humidity('HUMIDITY'),
  luminosity('LUMINOSITY'),
  rfidTag('RFID_TAG'),
  unknown('');

  const MonitoredMetric(this.code);

  final String code;

  /// Metrics with a numeric value that can be charted against thresholds.
  bool get isNumeric => this != motion && this != rfidTag && this != unknown;

  static MonitoredMetric fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return MonitoredMetric.unknown;
  }
}
