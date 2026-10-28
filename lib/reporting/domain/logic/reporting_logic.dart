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