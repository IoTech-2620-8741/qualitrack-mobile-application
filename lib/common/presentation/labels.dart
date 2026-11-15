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

/// Localized name of a status, cycle or type code sent by the backend
/// (`ACTIVE`, `MONTHLY`, `PREVENTIVE`…). A code it does not know is shown
/// humanized rather than raw, so the screen never shows `PENDING_PAYMENT`.
String codeLabel(AppLocalizations i18n, String? code) => switch (code?.toUpperCase()) {
  'ACTIVE' => i18n.active,
  'INACTIVE' => i18n.inactive,
  'PENDING' => i18n.codePending,
  'PENDING_PAYMENT' => i18n.codePendingPayment,
  'SUSPENDED' => i18n.codeSuspended,
  'CANCELLED' || 'CANCELED' => i18n.codeCancelled,
  'EXPIRED' => i18n.codeExpired,
  'PAID' || 'SUCCEEDED' => i18n.codePaid,
  'FAILED' => i18n.codeFailed,
  'REFUNDED' => i18n.codeRefunded,
  'MONTHLY' => i18n.codeMonthly,
  'QUARTERLY' => i18n.codeQuarterly,
  'ANNUAL' || 'YEARLY' => i18n.codeAnnual,
  'PREVENTIVE' => i18n.codePreventive,
  'CORRECTIVE' => i18n.codeCorrective,
  'CALIBRATION' => i18n.codeCalibration,
  'INSPECTION' => i18n.codeInspection,
  'CLEANING' => i18n.codeCleaning,
  'BATCH_RELEASED' => i18n.codeBatchReleased,
  'BATCH_REJECTED' => i18n.codeBatchRejected,
  'BATCH_BLOCKED' => i18n.codeBatchBlocked,
  'CREATE' || 'CREATED' => i18n.codeCreated,
  'UPDATE' || 'UPDATED' => i18n.codeUpdated,
  'DELETE' || 'DELETED' => i18n.codeDeleted,
  _ => Formatters.humanize(code),
};

/// A regulation code as it is written: `BPM_DIGEMID` → `BPM DIGEMID`.
String regulationLabel(String code) => code.replaceAll('_', ' ');

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
