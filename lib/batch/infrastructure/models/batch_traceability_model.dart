import '../../../shared/infrastructure/http/json_utils.dart';
import '../../domain/entities/batch_traceability.dart';
import 'production_batch_model.dart';

/// `BatchTraceabilityResource {batch, product, rawMaterials, equipment, staff,
/// release, rejection, container}`.
class BatchTraceabilityModel extends BatchTraceability {
  const BatchTraceabilityModel({
    required super.batch,
    super.productCode,
    super.rawMaterials,
    super.equipment,
    super.staff,
    super.release,
    super.rejection,
    super.container,
  });

  factory BatchTraceabilityModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? object(String key) => json[key] == null ? null : Json.asMap(json[key]);
    List<Map<String, dynamic>> list(String key) => json[key] == null ? const [] : Json.asList(json[key]);

    final product = object('product');
    final release = object('release');
    final rejection = object('rejection');
    final container = object('container');
    return BatchTraceabilityModel(
      batch: ProductionBatchModel.fromJson(Json.asMap(json['batch'])),
      productCode: product == null ? null : Json.optString(product, 'code'),
      rawMaterials: [for (final item in list('rawMaterials')) RawMaterialUsageModel.fromJson(item)],
      equipment: [for (final item in list('equipment')) BatchEquipmentUsageModel.fromJson(item)],
      staff: [for (final item in list('staff')) BatchStaffParticipationModel.fromJson(item)],
      release: release == null ? null : BatchReleaseModel.fromJson(release),
      rejection: rejection == null ? null : BatchRejectionModel.fromJson(rejection),
      container: container == null ? null : BatchContainerModel.fromJson(container),
    );
  }
}

class RawMaterialUsageModel extends RawMaterialUsage {
  const RawMaterialUsageModel({
    required super.id,
    required super.rawMaterialId,
    super.rawMaterialName,
    super.rawMaterialEnvironmentId,
    super.quantityUsed,
    super.unit,
    super.usageDate,
    super.stockBefore,
    super.stockAfter,
    super.inventoryReceiptId,
  });

  factory RawMaterialUsageModel.fromJson(Map<String, dynamic> json) => RawMaterialUsageModel(
    id: Json.requireInt(json, 'id'),
    rawMaterialId: Json.requireInt(json, 'rawMaterialId'),
    rawMaterialName: Json.optString(json, 'rawMaterialName'),
    rawMaterialEnvironmentId: Json.optInt(json, 'rawMaterialEnvironmentId'),
    quantityUsed: Json.optDouble(json, 'quantityUsed'),
    unit: Json.optString(json, 'unit'),
    usageDate: Json.optDateTime(json, 'usageDate'),
    stockBefore: Json.optDouble(json, 'stockBefore'),
    stockAfter: Json.optDouble(json, 'stockAfter'),
    inventoryReceiptId: Json.optInt(json, 'inventoryReceiptId'),
  );
}

class BatchEquipmentUsageModel extends BatchEquipmentUsage {
  const BatchEquipmentUsageModel({required super.equipmentId, required super.equipmentName, super.registeredAt});

  factory BatchEquipmentUsageModel.fromJson(Map<String, dynamic> json) => BatchEquipmentUsageModel(
    equipmentId: Json.requireInt(json, 'equipmentId'),
    equipmentName: Json.requireString(json, 'equipmentName'),
    registeredAt: Json.optDateTime(json, 'registeredAt'),
  );
}

class BatchStaffParticipationModel extends BatchStaffParticipation {
  const BatchStaffParticipationModel({
    required super.staffId,
    required super.staffName,
    super.staffRole,
    super.registeredAt,
  });

  factory BatchStaffParticipationModel.fromJson(Map<String, dynamic> json) => BatchStaffParticipationModel(
    staffId: Json.requireInt(json, 'staffId'),
    staffName: Json.requireString(json, 'staffName'),
    staffRole: Json.optString(json, 'staffRole'),
    registeredAt: Json.optDateTime(json, 'registeredAt'),
  );
}

class BatchReleaseModel extends BatchRelease {
  const BatchReleaseModel({required super.signedByUserId, required super.signatureHash, super.signedAt});

  factory BatchReleaseModel.fromJson(Map<String, dynamic> json) => BatchReleaseModel(
    signedByUserId: Json.requireInt(json, 'signedByUserId'),
    signatureHash: Json.requireString(json, 'signatureHash'),
    signedAt: Json.optDateTime(json, 'signedAt'),
  );
}

class BatchRejectionModel extends BatchRejection {
  const BatchRejectionModel({required super.reason, super.rejectionDate});

  factory BatchRejectionModel.fromJson(Map<String, dynamic> json) => BatchRejectionModel(
    reason: Json.requireString(json, 'reason'),
    rejectionDate: Json.optString(json, 'rejectionDate'),
  );
}

class BatchContainerModel extends BatchContainer {
  const BatchContainerModel({
    required super.containerMonitorId,
    super.containerName,
    super.environmentId,
    super.assignedAt,
  });

  factory BatchContainerModel.fromJson(Map<String, dynamic> json) => BatchContainerModel(
    containerMonitorId: Json.requireInt(json, 'containerMonitorId'),
    containerName: Json.optString(json, 'containerName'),
    environmentId: Json.optInt(json, 'environmentId'),
    assignedAt: Json.optDateTime(json, 'assignedAt'),
  );
}
