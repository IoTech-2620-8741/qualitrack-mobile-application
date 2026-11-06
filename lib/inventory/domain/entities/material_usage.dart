import 'package:equatable/equatable.dart';

/// Quantity of the material consumed by a product batch (TS: affected batches).
class MaterialUsage extends Equatable {
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
