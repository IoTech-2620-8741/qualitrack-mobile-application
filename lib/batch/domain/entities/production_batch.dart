import 'package:equatable/equatable.dart';

import 'batch_status.dart';

/// `BatchResource` (Product Batch Management). A batch is the fabrication of
/// a product registered in an environment; it starts PENDING and is IN_PROGRESS
/// once its first raw material is consumed.
class ProductionBatch extends Equatable {
  const ProductionBatch({
    required this.id,
    required this.labId,
    required this.productId,
    required this.batchNumber,
    required this.status,
    this.environmentId,
    this.productName,
    this.quantity,
    this.unit,
    this.startDate,
    this.endDate,
    this.notes,
    this.containerMonitorId,
  });

  final int id;
  final int labId;
  final int? environmentId;
  final int productId;
  final String? productName;
  final String batchNumber;
  final double? quantity;
  final String? unit;
  final BatchStatus status;

  /// ISO dates as sent by the backend (`yyyy-MM-dd`).
  final String? startDate;
  final String? endDate;
  final String? notes;
  final int? containerMonitorId;

  /// Released or rejected batches are closed, so only open batches offer the
  /// quality decision in the UI.
  bool get isAwaitingReview => status == BatchStatus.pending || status == BatchStatus.inProgress;

  /// First day the quality decision can be dated: the start of the batch, or
  /// [today] when the batch starts later. Without a start date, five years back.
  DateTime firstDecisionDay(DateTime today) {
    final todayDay = DateTime(today.year, today.month, today.day);
    final start = DateTime.tryParse(startDate ?? '');
    if (start == null) return DateTime(today.year - 5, today.month, today.day);
    final startDay = DateTime(start.year, start.month, start.day);
    return startDay.isAfter(todayDay) ? todayDay : startDay;
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return batchNumber.toLowerCase().contains(q) ||
        (productName?.toLowerCase().contains(q) ?? false) ||
        (notes?.toLowerCase().contains(q) ?? false);
  }

  @override
  List<Object?> get props => [
    id,
    labId,
    environmentId,
    productId,
    productName,
    batchNumber,
    quantity,
    unit,
    status,
    startDate,
    endDate,
    notes,
    containerMonitorId,
  ];
}
