/// `IotDeviceType`: the IoT role of an equipment, if it has one. An
/// environmental device supervises a whole environment (one per environment);
/// a container monitor supervises a container where lots are stored.
enum IotDeviceType {
  environmentalDevice('ENVIRONMENTAL_DEVICE'),
  containerMonitor('CONTAINER_MONITOR');

  const IotDeviceType(this.code);

  final String code;

  static IotDeviceType? fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
