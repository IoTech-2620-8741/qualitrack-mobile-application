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

/// `BatchResource` (Product Batch Management). A batch is the fabrication of
/// a product registered in an environment; it starts PENDING and is IN_PROGRESS
/// once its first raw material is consumed.
final class ProductionBatch extends Equatable {
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

/// Raw material lot consumed by the batch, with the stock before and after.
final class RawMaterialUsage extends Equatable {
  const RawMaterialUsage({
    required this.id,
    required this.rawMaterialId,
    this.rawMaterialName,
    this.rawMaterialEnvironmentId,
    this.quantityUsed,
    this.unit,
    this.usageDate,
    this.stockBefore,
    this.stockAfter,
    this.inventoryReceiptId,
  });

  final int id;
  final int rawMaterialId;
  final String? rawMaterialName;
  final int? rawMaterialEnvironmentId;
  final double? quantityUsed;
  final String? unit;
  final DateTime? usageDate;
  final double? stockBefore;
  final double? stockAfter;

  /// Raw material lot (receipt) the quantity was taken from.
  final int? inventoryReceiptId;

  @override
  List<Object?> get props => [
    id,
    rawMaterialId,
    rawMaterialName,
    rawMaterialEnvironmentId,
    quantityUsed,
    unit,
    usageDate,
    stockBefore,
    stockAfter,
    inventoryReceiptId,
  ];
}

/// Equipment used in the fabrication.
final class BatchEquipmentUsage extends Equatable {
  const BatchEquipmentUsage({required this.equipmentId, required this.equipmentName, this.registeredAt});

  final int equipmentId;
  final String equipmentName;
  final DateTime? registeredAt;

  @override
  List<Object?> get props => [equipmentId, equipmentName, registeredAt];
}

/// Person who took part in the fabrication.
final class BatchStaffParticipation extends Equatable {
  const BatchStaffParticipation({required this.staffId, required this.staffName, this.staffRole, this.registeredAt});

  final int staffId;
  final String staffName;
  final String? staffRole;
  final DateTime? registeredAt;

  @override
  List<Object?> get props => [staffId, staffName, staffRole, registeredAt];
}

/// Digital signature of the release: who signed, when, and the SHA-256 hash.
final class BatchRelease extends Equatable {
  const BatchRelease({required this.signedByUserId, required this.signatureHash, this.signedAt});

  final int signedByUserId;
  final String signatureHash;
  final DateTime? signedAt;

  @override
  List<Object?> get props => [signedByUserId, signatureHash, signedAt];
}

final class BatchRejection extends Equatable {
  const BatchRejection({required this.reason, this.rejectionDate});

  final String reason;
  final String? rejectionDate;

  @override
  List<Object?> get props => [reason, rejectionDate];
}

/// Container monitor where the batch is stored.
final class BatchContainer extends Equatable {
  const BatchContainer({required this.containerMonitorId, this.containerName, this.environmentId, this.assignedAt});

  final int containerMonitorId;
  final String? containerName;
  final int? environmentId;
  final DateTime? assignedAt;

  @override
  List<Object?> get props => [containerMonitorId, containerName, environmentId, assignedAt];
}

/// `BatchTraceabilityResource`: everything that took part in a batch and the
/// quality decision.
final class BatchTraceability extends Equatable {
  const BatchTraceability({
    required this.batch,
    this.productCode,
    this.rawMaterials = const [],
    this.equipment = const [],
    this.staff = const [],
    this.release,
    this.rejection,
    this.container,
  });

  final ProductionBatch batch;
  final String? productCode;
  final List<RawMaterialUsage> rawMaterials;
  final List<BatchEquipmentUsage> equipment;
  final List<BatchStaffParticipation> staff;
  final BatchRelease? release;
  final BatchRejection? rejection;
  final BatchContainer? container;

  @override
  List<Object?> get props => [batch, productCode, rawMaterials, equipment, staff, release, rejection, container];
}

abstract interface class BatchRepository {
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId);
  Future<BatchTraceability> getTraceability(LaboratoryId laboratoryId, ProductionBatch batch);
  Future<void> release(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String releaseDate,
    required String notes,
  });
  Future<void> reject(
    LaboratoryId laboratoryId,
    ProductionBatch batch, {
    required String rejectionDate,
    required String reason,
  });
}
