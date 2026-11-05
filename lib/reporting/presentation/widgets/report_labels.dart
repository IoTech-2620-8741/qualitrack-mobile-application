import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';

String reportPeriodLabel(AppLocalizations l10n, ReportPeriod period) =>
    switch (period) {
      ReportPeriod.last24Hours => l10n.period24h,
      ReportPeriod.last7Days => l10n.period7d,
      ReportPeriod.last31Days => l10n.period31d,
    };

String reportTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'BATCH_TRACEABILITY' => l10n.reportBatchTraceability,
  'COMPLIANCE_PERIOD' => l10n.reportCompliance,
  'EQUIPMENT_LOG' => l10n.reportEquipmentLog,
  'INVENTORY' => l10n.reportInventory,
  'KPI_SUMMARY' => l10n.reportKpiSummary,
  _ => Formatters.humanize(type),
};