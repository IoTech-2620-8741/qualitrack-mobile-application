import '../entities/reporting_entities.dart';

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

int deviationSeverityRank(DeviationTrend t) => switch (t.severity) {
  DeviationSeverity.critical => 0,
  DeviationSeverity.warning => 1,
  DeviationSeverity.onTrack => 2,
  DeviationSeverity.noData => 3,
};

List<DeviationTrend> sortTrendsBySeverity(List<DeviationTrend> trends) {
  return [...trends]..sort((a, b) {
    final bySeverity = deviationSeverityRank(a).compareTo(deviationSeverityRank(b));
    if (bySeverity != 0) return bySeverity;
    final aPercent = a.timeInRangePercent ?? double.infinity;
    final bPercent = b.timeInRangePercent ?? double.infinity;
    final byPercent = aPercent.compareTo(bPercent);
    if (byPercent != 0) return byPercent;
    return a.parameterName.compareTo(b.parameterName);
  });
}