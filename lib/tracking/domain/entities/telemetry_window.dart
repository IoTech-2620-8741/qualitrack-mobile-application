/// Chart window options offered by the telemetry dashboard.
enum TelemetryWindow {
  fifteenMinutes(Duration(minutes: 15)),
  oneHour(Duration(hours: 1)),
  sixHours(Duration(hours: 6)),
  twentyFourHours(Duration(hours: 24));

  const TelemetryWindow(this.duration);

  final Duration duration;
}
