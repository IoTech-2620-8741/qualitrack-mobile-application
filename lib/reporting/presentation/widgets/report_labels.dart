/// This file contains helper functions to generate localized labels
/// for the Reporting context.
///
/// It centralizes the translation and formatting logic, keeping the UI widgets clean.
///
/// @author Vitaly Baca Camargo
///
/// @version 1.0.0
library;

import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../domain/entities/reporting_enums.dart';

/// Returns the localized label for a given [ReportPeriod].
///
/// @param i18n The localization object.
/// @param period The period enum.
/// @return The translated string (e.g., "24 horas", "7 días", etc.).
String reportPeriodLabel(AppLocalizations i18n, ReportPeriod period) =>
    switch (period) {
      ReportPeriod.last24Hours => i18n.period24h,
      ReportPeriod.last7Days => i18n.period7d,
      ReportPeriod.last31Days => i18n.period31d,
    };

/// Returns the localized label for a given report type code.
///
/// If the type is not recognized, it falls back to a humanized version
/// of the raw string using [Formatters.humanize].
///
/// @param i18n The localization object.
/// @param type The raw report type code (e.g., 'BATCH_TRACEABILITY').
/// @return The translated string.
String reportTypeLabel(AppLocalizations i18n, String type) => switch (type) {
  'BATCH_TRACEABILITY' => i18n.reportBatchTraceability,
  'COMPLIANCE_PERIOD' => i18n.reportCompliance,
  'EQUIPMENT_LOG' => i18n.reportEquipmentLog,
  'INVENTORY' => i18n.reportInventory,
  'KPI_SUMMARY' => i18n.reportKpiSummary,
  _ => Formatters.humanize(type),
};