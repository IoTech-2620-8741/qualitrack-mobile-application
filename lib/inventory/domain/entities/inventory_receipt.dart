import 'package:equatable/equatable.dart';

import 'receipt_status.dart';

/// Lot received from a supplier (`ReceiptResource`). It starts in quarantine
/// and can be consumed only once released and before it expires.
class InventoryReceipt extends Equatable {
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
