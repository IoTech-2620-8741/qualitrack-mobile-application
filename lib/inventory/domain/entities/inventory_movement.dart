import 'package:equatable/equatable.dart';

/// Stock or review movement (`InventoryMovementResource`): `RECEIPT`,
/// `REVIEW`, `STORAGE` or `CONSUMPTION`.
class InventoryMovement extends Equatable {
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
