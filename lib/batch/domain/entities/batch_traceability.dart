import 'package:equatable/equatable.dart';

import 'production_batch.dart';

/// Raw material lot consumed by the batch, with the stock before and after.
class RawMaterialUsage extends Equatable {
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
class BatchEquipmentUsage extends Equatable {
  const BatchEquipmentUsage({required this.equipmentId, required this.equipmentName, this.registeredAt});

  final int equipmentId;
  final String equipmentName;
  final DateTime? registeredAt;

  @override
  List<Object?> get props => [equipmentId, equipmentName, registeredAt];
}

/// Person who took part in the fabrication.
class BatchStaffParticipation extends Equatable {
  const BatchStaffParticipation({required this.staffId, required this.staffName, this.staffRole, this.registeredAt});

  final int staffId;
  final String staffName;
  final String? staffRole;
  final DateTime? registeredAt;

  @override
  List<Object?> get props => [staffId, staffName, staffRole, registeredAt];
}

/// Digital signature of the release: who signed, when, and the SHA-256 hash.
class BatchRelease extends Equatable {
  const BatchRelease({required this.signedByUserId, required this.signatureHash, this.signedAt});

  final int signedByUserId;
  final String signatureHash;
  final DateTime? signedAt;

  @override
  List<Object?> get props => [signedByUserId, signatureHash, signedAt];
}

class BatchRejection extends Equatable {
  const BatchRejection({required this.reason, this.rejectionDate});

  final String reason;
  final String? rejectionDate;

  @override
  List<Object?> get props => [reason, rejectionDate];
}

/// Container monitor where the batch is stored.
class BatchContainer extends Equatable {
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
class BatchTraceability extends Equatable {
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
