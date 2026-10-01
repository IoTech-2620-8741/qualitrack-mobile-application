import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

enum BatchStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  released('RELEASED'),
  rejected('REJECTED'),
  unknown('UNKNOWN');

  const BatchStatus(this.code);

  final String code;

  static BatchStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return BatchStatus.unknown;
  }
}

/// `BatchResource` (Product Batch Management).
final class ProductionBatch extends Equatable {
  const ProductionBatch({
    required this.id,
    required this.labId,
    required this.batchNumber,
    required this.status,
    this.productId,
    this.productName,
    this.quantity,
    this.unit,
    this.startDate,
    this.endDate,
    this.notes,
  });

  final int id;
  final int labId;
  final int? productId;
  final String? productName;
  final String batchNumber;
  final double? quantity;
  final String? unit;
  final BatchStatus status;

  /// ISO dates as sent by the backend (`yyyy-MM-dd`).
  final String? startDate;
  final String? endDate;
  final String? notes;

  /// The aggregate rejects release of REJECTED and rejection of RELEASED
  /// batches, so only open batches offer review actions in the UI.
  bool get isAwaitingReview => status == BatchStatus.pending || status == BatchStatus.inProgress;

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
    productId,
    productName,
    batchNumber,
    quantity,
    unit,
    status,
    startDate,
    endDate,
    notes,
  ];
}

final class BatchSummary extends Equatable {
  const BatchSummary({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.released,
    required this.rejected,
  });

  factory BatchSummary.of(List<ProductionBatch> batches) => BatchSummary(
    total: batches.length,
    pending: batches.where((b) => b.status == BatchStatus.pending).length,
    inProgress: batches.where((b) => b.status == BatchStatus.inProgress).length,
    released: batches.where((b) => b.status == BatchStatus.released).length,
    rejected: batches.where((b) => b.status == BatchStatus.rejected).length,
  );

  final int total;
  final int pending;
  final int inProgress;
  final int released;
  final int rejected;

  @override
  List<Object?> get props => [total, pending, inProgress, released, rejected];
}

/// `RawMaterialUsageResource`: traceability between a batch and inventory.
final class RawMaterialUsage extends Equatable {
  const RawMaterialUsage({
    required this.id,
    required this.batchId,
    required this.rawMaterialId,
    this.rawMaterialName,
    this.quantityUsed,
    this.unit,
    this.usageDate,
    this.rawUsageDate,
    this.stockBefore,
    this.stockAfter,
    this.inventoryReceiptId,
  });

  final int id;
  final int batchId;
  final int rawMaterialId;
  final String? rawMaterialName;
  final double? quantityUsed;
  final String? unit;
  final DateTime? usageDate;
  final String? rawUsageDate;
  final double? stockBefore;
  final double? stockAfter;
  final int? inventoryReceiptId;

  @override
  List<Object?> get props => [
    id,
    batchId,
    rawMaterialId,
    rawMaterialName,
    quantityUsed,
    unit,
    usageDate,
    rawUsageDate,
    stockBefore,
    stockAfter,
    inventoryReceiptId,
  ];
}

abstract interface class BatchRepository {
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId);
  Future<ProductionBatch> getById(int batchId);
  Future<List<RawMaterialUsage>> getRawMaterialUsage(int batchId);
  Future<ProductionBatch> release({required int batchId, required String releaseDate, required String notes});
  Future<ProductionBatch> reject({required int batchId, required String rejectionDate, required String reason});
}
