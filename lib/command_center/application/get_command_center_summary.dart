import 'package:equatable/equatable.dart';

import '../../batch/application/batch_use_cases.dart';
import '../../batch/domain/batch.dart';
import '../../compliance/application/compliance_queries.dart';
import '../../compliance/domain/compliance.dart';
import '../../equipment/application/equipment_queries.dart';
import '../../equipment/domain/equipment.dart';
import '../../inventory/application/inventory_queries.dart';
import '../../inventory/domain/inventory.dart';
import '../../laboratory/application/laboratory_queries.dart';
import '../../laboratory/domain/laboratory.dart';
import '../../reporting/application/reporting_queries.dart';
import '../../reporting/domain/reporting.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../../subscription/domain/subscription.dart';
import '../../tracking/application/telemetry_queries.dart';
import '../../tracking/domain/telemetry.dart';

/// A value loaded independently for the Command Center.
final class Part<T> extends Equatable {
  const Part.ok(T this.value) : failure = null;
  const Part.failed(Failure this.failure) : value = null;

  final T? value;
  final Failure? failure;

  bool get isOk => failure == null;

  @override
  List<Object?> get props => [value, failure];
}

/// Operational overview computed only from real backend data.
final class CommandCenterSummary extends Equatable {
  const CommandCenterSummary({
    required this.laboratory,
    required this.equipment,
    required this.batches,
    required this.alerts,
    required this.materials,
    required this.kpi,
    required this.subscription,
  });

  final Part<Laboratory> laboratory;
  final Part<EquipmentSnapshot> equipment;
  final Part<BatchSummary> batches;
  final Part<AlertSummary> alerts;
  final Part<List<InventoryMaterial>> materials;
  final Part<KpiDashboard?> kpi;
  final Part<Subscription?> subscription;

  @override
  List<Object?> get props => [laboratory, equipment, batches, alerts, materials, kpi, subscription];
}

final class EquipmentSnapshot extends Equatable {
  const EquipmentSnapshot({required this.equipments, required this.statuses});

  final List<Equipment> equipments;
  final Map<int, EquipmentTelemetryStatus> statuses;

  int get total => equipments.length;
  int get operational => equipments.where((e) => e.status == EquipmentStatus.operational).length;
  int get online => statuses.values.where((s) => s.isOnline).length;
  int get telemetryAttention => statuses.values.where((s) => s.needsAttention).length;
  int get needingAttention => equipments
      .where((e) => e.needsAttention || (statuses[e.id]?.needsAttention ?? false))
      .length;
  int get maintenance => equipments.where((e) => e.status == EquipmentStatus.maintenance).length;

  @override
  List<Object?> get props => [equipments, statuses];
}

typedef ActiveSubscriptionLoader = Future<Subscription?> Function(LaboratoryId id);

class GetCommandCenterSummary {
  const GetCommandCenterSummary({
    required GetLaboratory getLaboratory,
    required GetEquipments getEquipments,
    required GetTelemetryStatuses getTelemetryStatuses,
    required GetBatches getBatches,
    required GetLaboratoryAlerts getAlerts,
    required GetInventoryMaterials getMaterials,
    required GetKpiDashboard getKpi,
    required ActiveSubscriptionLoader getActiveSubscription,
  }) : _getLaboratory = getLaboratory,
       _getEquipments = getEquipments,
       _getStatuses = getTelemetryStatuses,
       _getBatches = getBatches,
       _getAlerts = getAlerts,
       _getMaterials = getMaterials,
       _getKpi = getKpi,
       _getSubscription = getActiveSubscription;

  final GetLaboratory _getLaboratory;
  final GetEquipments _getEquipments;
  final GetTelemetryStatuses _getStatuses;
  final GetBatches _getBatches;
  final GetLaboratoryAlerts _getAlerts;
  final GetInventoryMaterials _getMaterials;
  final GetKpiDashboard _getKpi;
  final ActiveSubscriptionLoader _getSubscription;

  Future<CommandCenterSummary> call(LaboratoryId lab) async {
    final equipmentFuture = _part(() => _getEquipments(lab));
    final results = await Future.wait<Object>([
      _part(() => _getLaboratory(lab)),
      _part(() async => BatchSummary.of(await _getBatches(lab))),
      _part(() => _getMaterials(lab)),
      _part(() => _getKpi(lab)),
      _part(() => _getSubscription(lab)),
      equipmentFuture,
    ]);

    final equipmentPart = results[5] as Part<List<Equipment>>;
    Part<EquipmentSnapshot> equipment;
    Part<AlertSummary> alerts;
    if (equipmentPart.isOk) {
      final list = equipmentPart.value!;
      final ids = list.map((e) => e.id).toList();
      final both = await Future.wait<Object>([
        _part(() => _getStatuses(ids)),
        _part(() async => AlertSummary.of(await _getAlerts(ids))),
      ]);
      final statuses = both[0] as Part<Map<int, EquipmentTelemetryStatus>>;
      equipment = Part.ok(EquipmentSnapshot(
        equipments: list,
        statuses: statuses.value ?? const {},
      ));
      alerts = both[1] as Part<AlertSummary>;
    } else {
      equipment = Part.failed(equipmentPart.failure!);
      alerts = Part.failed(equipmentPart.failure!);
    }

    return CommandCenterSummary(
      laboratory: results[0] as Part<Laboratory>,
      batches: results[1] as Part<BatchSummary>,
      materials: results[2] as Part<List<InventoryMaterial>>,
      kpi: results[3] as Part<KpiDashboard?>,
      subscription: results[4] as Part<Subscription?>,
      equipment: equipment,
      alerts: alerts,
    );
  }

  /// Any authentication failure aborts the whole summary.
  static Future<Part<T>> _part<T>(Future<T> Function() load) async {
    try {
      return Part<T>.ok(await load());
    } on UnauthorizedFailure {
      rethrow;
    } on OnboardingRequiredFailure {
      rethrow;
    } on Failure catch (failure) {
      return Part<T>.failed(failure);
    }
  }
}
