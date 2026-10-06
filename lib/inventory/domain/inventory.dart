import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// Raw material of an environment (`RawMaterialResource`). Stock values are
/// derived by the backend from its lots.
final class InventoryMaterial extends Equatable {
  const InventoryMaterial({
    required this.id,
    required this.laboratoryId,
    required this.environmentId,
    required this.code,
    required this.name,
    required this.unit,
    required this.minimumStock,
    required this.usableStock,
    required this.physicalStock,
    this.stockStatus,
    this.legacyId,
  });

  final int id;
  final int laboratoryId;
  final int environmentId;
  final String code;
  final String name;
  final String unit;
  final double minimumStock;
  final double usableStock;
  final double physicalStock;

  /// `LOW` or `SUFFICIENT`, classified by the backend (TS27).
  final String? stockStatus;
  final int? legacyId;

  /// Same rule as the Web dashboard: usable stock below the minimum.
  bool get isBelowMinimum => stockStatus == null ? usableStock < minimumStock : stockStatus == 'LOW';

  /// Physical stock exists but part of it is not usable (quarantine, observed,
  /// rejected or expired receipts).
  bool get hasBlockedStock => physicalStock > usableStock;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    environmentId,
    code,
    name,
    unit,
    minimumStock,
    usableStock,
    physicalStock,
    stockStatus,
    legacyId,
  ];
}

enum ReceiptStatus {
  quarantined('QUARANTINED'),
  released('RELEASED'),
  observed('OBSERVED'),
  rejected('REJECTED'),
  unknown('UNKNOWN');

  const ReceiptStatus(this.code);

  final String code;

  static ReceiptStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return ReceiptStatus.unknown;
  }
}

/// Lot received from a supplier (`ReceiptResource`). It starts in quarantine
/// and can be consumed only once released and before it expires.
final class InventoryReceipt extends Equatable {
  const InventoryReceipt({
    required this.id,
    required this.rawMaterialId,
    required this.status,
    required this.usable,
    this.supplier,
    this.batchNumber,
    this.unit,
    this.initialAmount,
    this.availableAmount,
    this.receivedOn,
    this.expiresOn,
    this.availability,
    this.expirationStatus,
    this.containerMonitorId,
  });

  final int id;
  final int rawMaterialId;
  final String? supplier;
  final String? batchNumber;
  final String? unit;
  final double? initialAmount;
  final double? availableAmount;
  final DateTime? receivedOn;
  final DateTime? expiresOn;
  final ReceiptStatus status;
  final bool usable;

  /// `EXPIRED`, `NOT_YET_RECEIVED`, `DEPLETED` or the lot status.
  final String? availability;

  /// `VALID`, `NEAR_EXPIRY` or `EXPIRED`.
  final String? expirationStatus;

  /// Container monitor where the lot is stored, if any.
  final int? containerMonitorId;

  bool get isNearExpiry => expirationStatus == 'NEAR_EXPIRY';
  bool get isExpired => expirationStatus == 'EXPIRED';

  @override
  List<Object?> get props => [
    id,
    rawMaterialId,
    supplier,
    batchNumber,
    unit,
    initialAmount,
    availableAmount,
    receivedOn,
    expiresOn,
    status,
    usable,
    availability,
    expirationStatus,
    containerMonitorId,
  ];
}

/// Stock or review movement (`InventoryMovementResource`): `RECEIPT`,
/// `REVIEW`, `STORAGE` or `CONSUMPTION`.
final class InventoryMovement extends Equatable {
  const InventoryMovement({
    required this.id,
    required this.type,
    this.receiptId,
    this.productBatchId,
    this.amount,
    this.unit,
    this.stockBefore,
    this.stockAfter,
    this.statusBefore,
    this.statusAfter,
    this.reason,
    this.actorId,
    this.occurredAt,
  });

  final int id;
  final String type;
  final int? receiptId;
  final int? productBatchId;
  final double? amount;
  final String? unit;
  final double? stockBefore;
  final double? stockAfter;
  final String? statusBefore;
  final String? statusAfter;
  final String? reason;
  final int? actorId;
  final DateTime? occurredAt;

  @override
  List<Object?> get props => [
    id,
    type,
    receiptId,
    productBatchId,
    amount,
    unit,
    stockBefore,
    stockAfter,
    statusBefore,
    statusAfter,
    reason,
    actorId,
    occurredAt,
  ];
}

/// Quantity of the material consumed by a product batch (TS: affected batches).
final class MaterialUsage extends Equatable {
  const MaterialUsage({
    required this.id,
    required this.batchId,
    this.quantityUsed,
    this.unit,
    this.usageDate,
    this.inventoryReceiptId,
  });

  final int id;
  final int batchId;
  final double? quantityUsed;
  final String? unit;
  final DateTime? usageDate;
  final int? inventoryReceiptId;

  @override
  List<Object?> get props => [id, batchId, quantityUsed, unit, usageDate, inventoryReceiptId];
}

abstract interface class InventoryRepository {
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId, int environmentId);
  Future<InventoryMaterial> getMaterial(LaboratoryId laboratoryId, int environmentId, int materialId);
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, InventoryMaterial material);
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, InventoryMaterial material);
  Future<List<MaterialUsage>> getUsages(LaboratoryId laboratoryId, InventoryMaterial material);
}
