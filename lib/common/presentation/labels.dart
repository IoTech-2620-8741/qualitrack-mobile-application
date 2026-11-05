import 'formatting/formatters.dart';
import 'i18n/app_localizations.dart';

/// Localized name of a monitored variable by its backend code (e.g.
/// `TEMPERATURE`). Keyed by code so any context can name a variable without
/// importing the domain of Tracking & Telemetry.
String metricLabel(AppLocalizations i18n, String? code, {String? raw}) => switch (code) {
  'AIR_QUALITY' => i18n.metricAirQuality,
  'MOTION' => i18n.metricMotion,
  'TEMPERATURE' => i18n.metricTemperature,
  'HUMIDITY' => i18n.metricHumidity,
  'LUMINOSITY' => i18n.metricLuminosity,
  'RFID_TAG' => i18n.metricRfidTag,
  _ => raw ?? i18n.unknown,
};

/// Localized name of the monitored variable of an alert or report row.
String alertVariable(AppLocalizations i18n, String parameterName) =>
    metricLabel(i18n, parameterName, raw: Formatters.humanize(parameterName));

/// Localized name of an `ActuationAction` (e.g. `COOLING_ON`).
String actuationLabel(AppLocalizations i18n, String action) => switch (action) {
  'VENTILATION_ON' => i18n.actionVentilationOn,
  'VENTILATION_OFF' => i18n.actionVentilationOff,
  'COOLING_ON' => i18n.actionCoolingOn,
  'COOLING_OFF' => i18n.actionCoolingOff,
  'SERVO_OPEN' => i18n.actionServoOpen,
  'SERVO_CLOSE' => i18n.actionServoClose,
  _ => action,
};
