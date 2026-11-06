/// Barrel file that exports all reporting domain entities.
///
/// This allows other layers (Application, Infrastructure, Presentation)
/// to import just this file to access all domain models at once.
library;

export 'reporting_enums.dart';
export 'kpi_entities.dart';
export 'audit_entities.dart';
export 'deviation_entities.dart';