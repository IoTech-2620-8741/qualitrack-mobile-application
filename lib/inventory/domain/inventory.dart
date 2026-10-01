import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// Inventory catalogue entry (`inventory.RawMaterialResource`). Stock values
/// are derived by the backend from receipts.
final class InventoryMaterial extends Equatable {
  const InventoryMaterial({
    required this.id,
    required this.laboratoryId,
    required this.code,
    required this.name,
    required this.unit,
    required this.minimumStock,
    required this.usableStock,
    required this.physicalStock,
    this.legacyId,
  });

  final int id;
  final int laboratoryId;
  final String code;
  final String name;
  final String unit;
  final double minimumStock;
  final double usableStock;
  final double physicalStock;
  final int? legacyId;

  /// Same rule as the Web dashboard: usable stock below the minimum.
  bool get isBelowMinimum => usableStock < minimumStock;

  /// Physical stock exists but part of it is not usable (quarantine, observed,
  /// rejected or expired receipts).
  bool get hasBlockedStock => physicalStock > usableStock;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [id, laboratoryId, code, name, unit, minimumStock, usableStock, physicalStock, legacyId];
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

/// Supplier receipt (`ReceiptResource`).
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
  final String? availability;

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
  ];
}

/// Stock/review audit entry (`InventoryMovementResource`).
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

abstract interface class InventoryRepository {
  Future<List<InventoryMaterial>> getMaterials(LaboratoryId laboratoryId);
  Future<List<InventoryReceipt>> getReceipts(LaboratoryId laboratoryId, int materialId);
  Future<List<InventoryMovement>> getMovements(LaboratoryId laboratoryId, int materialId);
}
