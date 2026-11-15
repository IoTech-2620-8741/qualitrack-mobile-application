/// This file contains the pure business rules (domain logic)
/// for sorting reports, logs, and deviation trends.
///
/// It has no dependencies on Flutter, databases, or infrastructure.
///
library;

import '../entities/audit_entities.dart';
import '../entities/deviation_entities.dart';
import '../entities/reporting_enums.dart';

/// Business rules of Reporting & Audit. Pure Dart: the facade applies them on top
/// of the repository.
mixin ReportingLogic {
  /// Sorts a list of audit reports in descending order (newest first).
  ///
  /// Rules:
  /// 1. If both have a date, sorts by descending date.
  /// 2. If one lacks a date, it goes to the end.
  /// 3. If both lack a date, breaks the tie using the descending ID.
  ///
  /// @param reports The original list of [AuditReport].
  /// @return A new sorted list.
  List<AuditReport> sortReportsNewestFirst(List<AuditReport> reports) {
    return [...reports]..sort((a, b) {
      final left = a.generatedAt;
      final right = b.generatedAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }

  /// Sorts a list of audit log entries in descending order (newest first).
  ///
  /// Rules:
  /// 1. If both have a timestamp, sorts by descending date.
  /// 2. If one lacks a timestamp, it goes to the end.
  /// 3. If both lack a timestamp, breaks the tie using the descending ID.
  ///
  /// @param entries The original list of [AuditLogEntry].
  /// @return A new sorted list.
  List<AuditLogEntry> sortAuditLogsNewestFirst(List<AuditLogEntry> entries) {
    return [...entries]..sort((a, b) {
      final left = a.timestamp;
      final right = b.timestamp;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }

  /// Assigns a numeric rank to each severity level for sorting purposes.
  ///
  /// Critical (0) comes first, followed by Warning (1), On Track (2),
  /// and No Data (3) at the end.
  int deviationSeverityRank(DeviationTrend t) => switch (t.severity) {
    DeviationSeverity.critical => 0,
    DeviationSeverity.warning => 1,
    DeviationSeverity.onTrack => 2,
    DeviationSeverity.noData => 3,
  };

  /// Sorts a list of deviation trends based on business priority.
  ///
  /// Rules:
  /// 1. Primary sort: By severity (Critical > Warning > On Track > No Data).
  /// 2. Secondary sort: By `timeInRangePercent` (lower percentage comes first,
  ///    meaning worse performance). Null values are treated as infinity.
  /// 3. Tertiary sort: Alphabetical by parameter name.
  ///
  /// @param trends The original list of [DeviationTrend].
  /// @return A new sorted list.
  List<DeviationTrend> sortTrendsBySeverity(List<DeviationTrend> trends) {
    return [...trends]..sort((a, b) {
      // 1. Sort by Severity
      final bySeverity = deviationSeverityRank(a).compareTo(deviationSeverityRank(b));
      if (bySeverity != 0) return bySeverity;

      // 2. Sort by Time in Range (ascending)
      final aPercent = a.timeInRangePercent ?? double.infinity;
      final bPercent = b.timeInRangePercent ?? double.infinity;
      final byPercent = aPercent.compareTo(bPercent);
      if (byPercent != 0) return byPercent;

      // 3. Sort by Parameter Name (alphabetical)
      return a.parameterName.compareTo(b.parameterName);
    });
  }
}
