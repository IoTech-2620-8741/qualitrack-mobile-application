/// This file contains helper functions to generate localized labels
/// for the Reporting context.
///
/// It centralizes the translation and formatting logic, keeping the UI widgets clean.
///
/// @author Vitaly Baca Camargo
///
/// @version 1.0.0
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_enums.dart';

/// Returns the localized label for a given [ReportPeriod].
///
/// @param l10n The localization object.
/// @param period The period enum.
/// @return The translated string (e.g., "24 horas", "7 días", etc.).
String reportPeriodLabel(AppLocalizations l10n, ReportPeriod period) =>
    switch (period) {
      ReportPeriod.last24Hours => l10n.period24h,
      ReportPeriod.last7Days => l10n.period7d,
      ReportPeriod.last31Days => l10n.period31d,
    };

/// Returns the localized label for a given report type code.
///
/// If the type is not recognized, it falls back to a humanized version
/// of the raw string using [Formatters.humanize].
///
/// @param l10n The localization object.
/// @param type The raw report type code (e.g., 'BATCH_TRACEABILITY').
/// @return The translated string.
String reportTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'BATCH_TRACEABILITY' => l10n.reportBatchTraceability,
  'COMPLIANCE_PERIOD' => l10n.reportCompliance,
  'EQUIPMENT_LOG' => l10n.reportEquipmentLog,
  'INVENTORY' => l10n.reportInventory,
  'KPI_SUMMARY' => l10n.reportKpiSummary,
  _ => Formatters.humanize(type),
};