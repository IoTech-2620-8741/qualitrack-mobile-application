import 'formatting/formatters.dart';
import 'l10n/app_localizations.dart';

/// Localized name of a monitored variable by its backend code (e.g.
/// `TEMPERATURE`). Keyed by code so any context can name a variable without
/// importing the domain of Tracking & Telemetry.
String metricLabel(AppLocalizations l10n, String? code, {String? raw}) => switch (code) {
  'AIR_QUALITY' => l10n.metricAirQuality,
  'MOTION' => l10n.metricMotion,
  'TEMPERATURE' => l10n.metricTemperature,
  'HUMIDITY' => l10n.metricHumidity,
  'LUMINOSITY' => l10n.metricLuminosity,
  'RFID_TAG' => l10n.metricRfidTag,
  _ => raw ?? l10n.unknown,
};

/// Localized name of the monitored variable of an alert or report row.
String alertVariable(AppLocalizations l10n, String parameterName) =>
    metricLabel(l10n, parameterName, raw: Formatters.humanize(parameterName));

/// Localized name of an `ActuationAction` (e.g. `COOLING_ON`).
String actuationLabel(AppLocalizations l10n, String action) => switch (action) {
  'VENTILATION_ON' => l10n.actionVentilationOn,
  'VENTILATION_OFF' => l10n.actionVentilationOff,
  'COOLING_ON' => l10n.actionCoolingOn,
  'COOLING_OFF' => l10n.actionCoolingOff,
  'SERVO_OPEN' => l10n.actionServoOpen,
  'SERVO_CLOSE' => l10n.actionServoClose,
  _ => action,
};
