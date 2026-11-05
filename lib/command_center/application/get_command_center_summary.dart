import 'package:equatable/equatable.dart';

import '../../batch/api/index.dart';
import '../../compliance/api/index.dart';
import '../../equipment/api/index.dart';
import '../../inventory/api/index.dart';
import '../../laboratory/api/index.dart';
import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../../subscription/api/index.dart';
import '../../tracking/api/index.dart';

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

/// Equipment of the laboratory and the connection of its IoT devices.
final class EquipmentSnapshot extends Equatable {
  const EquipmentSnapshot({required this.equipments, required this.connections});

  final List<Equipment> equipments;
  final Map<int, DeviceConnection> connections;

  int get total => equipments.length;
  int get operational => equipments.where((e) => e.status == EquipmentStatus.operational).length;
  int get maintenance => equipments.where((e) => e.status == EquipmentStatus.maintenance).length;
  int get devices => telemetryDevices(equipments).length;
  int get connected => connections.values.where((c) => c.isConnected).length;
  int get requiresReview => connections.values.where((c) => c.status == ConnectionStatus.requiresReview).length;

  @override
  List<Object?> get props => [equipments, connections];
}

/// Batches of the laboratory with the most recent ones.
final class BatchOverview extends Equatable {
  const BatchOverview({required this.summary, required this.recent});

  final BatchSummary summary;
  final List<ProductionBatch> recent;

  @override
  List<Object?> get props => [summary, recent];
}

/// Open alerts of every environment, most urgent first.
final class AlertOverview extends Equatable {
  const AlertOverview({required this.summary, required this.open});

  final AlertSummary summary;
  final List<DeviationAlert> open;

  @override
  List<Object?> get props => [summary, open];
}

/// Operational overview of the laboratory, the same cards as the Web
/// dashboard: equipment, batches in progress, open alerts, low stock and, for
/// quality managers, the subscription.
final class CommandCenterSummary extends Equatable {
  const CommandCenterSummary({
    required this.laboratory,
    required this.equipment,
    required this.batches,
    required this.alerts,
    required this.materials,
    required this.subscription,
    this.environmentNames = const {},
  });

  final Part<Laboratory> laboratory;
  final Part<EquipmentSnapshot> equipment;
  final Part<BatchOverview> batches;
  final Part<AlertOverview> alerts;
  final Part<List<InventoryMaterial>> materials;

  /// Null for staff members: the subscription belongs to the quality manager.
  final Part<BillingSummary>? subscription;
  final Map<int, String> environmentNames;

  /// Equipment names by id, to name the device of each open alert.
  Map<int, String> get equipmentNames => {for (final e in equipment.value?.equipments ?? const <Equipment>[]) e.id: e.name};

  @override
  List<Object?> get props => [laboratory, equipment, batches, alerts, materials, subscription, environmentNames];
}

class GetCommandCenterSummary {
  const GetCommandCenterSummary({
    required LaboratoryApi laboratoryApi,
    required GetEquipments getEquipments,
    required GetDeviceConnections getConnections,
    required BatchApi batchApi,
    required GetLaboratoryAlerts getAlerts,
    required InventoryApi inventoryApi,
    required SubscriptionApi subscriptionApi,
  }) : _laboratoryApi = laboratoryApi,
       _getEquipments = getEquipments,
       _getConnections = getConnections,
       _batchApi = batchApi,
       _getAlerts = getAlerts,
       _inventoryApi = inventoryApi,
       _subscriptionApi = subscriptionApi;

  final LaboratoryApi _laboratoryApi;
  final GetEquipments _getEquipments;
  final GetDeviceConnections _getConnections;
  final BatchApi _batchApi;
  final GetLaboratoryAlerts _getAlerts;
  final InventoryApi _inventoryApi;
  final SubscriptionApi _subscriptionApi;

  Future<CommandCenterSummary> call(LaboratoryId lab, {required bool includeSubscription}) async {
    final environmentsPart = await _part(() => _laboratoryApi.getEnvironments(lab));
    final environmentIds = environmentsPart.value?.map((e) => e.id).toList();
    Future<Part<T>> perEnvironment<T>(Future<T> Function(List<int> ids) load) => environmentIds == null
        ? Future.value(Part<T>.failed(environmentsPart.failure!))
        : _part(() => load(environmentIds));

    final results = await Future.wait<Object?>([
      _part(() => _laboratoryApi.getLaboratory(lab)),
      _part(() async {
        final equipments = await _getEquipments(lab);
        final targets = equipments.map(targetOf).whereType<TelemetryTarget>().toList();
        return EquipmentSnapshot(equipments: equipments, connections: await _getConnections(lab, targets));
      }),
      _part(() async {
        final batches = await _batchApi.getBatches(lab);
        final recent = [...batches]..sort((a, b) => b.id.compareTo(a.id));
        return BatchOverview(summary: BatchSummary.of(batches), recent: recent.take(4).toList());
      }),
      perEnvironment((ids) async {
        final alerts = await _getAlerts(lab, ids);
        final open = alerts.where((a) => a.isOpen).toList();
        return AlertOverview(summary: AlertSummary.of(alerts), open: open);
      }),
      perEnvironment((ids) => _inventoryApi.getMaterials(lab, ids)),
      includeSubscription ? _part(() => _subscriptionApi.getBillingSummary(lab)) : Future<Part<BillingSummary>?>.value(),
    ]);

    return CommandCenterSummary(
      laboratory: results[0]! as Part<Laboratory>,
      equipment: results[1]! as Part<EquipmentSnapshot>,
      batches: results[2]! as Part<BatchOverview>,
      alerts: results[3]! as Part<AlertOverview>,
      materials: results[4]! as Part<List<InventoryMaterial>>,
      subscription: results[5] as Part<BillingSummary>?,
      environmentNames: {for (final e in environmentsPart.value ?? const <LabEnvironment>[]) e.id: e.name},
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
